#include <conio.h>
#include <cstdio>
#include <filesystem>
#include <string>
#include <vector>
#include <windows.h>

#include "detours.h"
#include "thmj4n.h"

extern "C" {
    #include "blowfish.h"
}

typedef WINAPI HANDLE (* CreateFileA_t)(LPCSTR, DWORD, DWORD, LPSECURITY_ATTRIBUTES, DWORD, DWORD, HANDLE);
typedef WINAPI BOOL (* CloseHandle_t)(HANDLE);
typedef WINAPI BOOL (* ReadFile_t)(HANDLE, LPVOID, DWORD, LPDWORD, LPOVERLAPPED);

CreateFileA_t CreateFileA_ = CreateFileA;
CloseHandle_t CloseHandle_ = CloseHandle;
ReadFile_t ReadFile_ = ReadFile;

std::string stem_name = "";
std::string pack_name = "";
HANDLE pack_file = NULL;

typedef struct {
    uint32_t magic;
    uint32_t count;
} __attribute__((packed)) pack_header_t;

typedef struct {
    char name[64];
    uint32_t crc32_name;
    uint32_t crc32_data;

    uint32_t start;
    uint32_t length;
} __attribute__((packed)) pack_entry_t;

typedef struct {
    pack_header_t header;
    pack_entry_t entries[];
} __attribute__((packed)) pack_t;

typedef struct {
    char name[64];
    uint32_t start;

    uint32_t old_length;
    uint32_t new_length;

    std::vector<uint8_t> data;
} patch_t;

typedef struct {
    uint32_t magic;
    uint32_t size;
} __attribute__((packed)) patch_header_t;

std::vector<patch_t> patches;

pack_t *fake_pack = NULL;
size_t entries_end = 0;

template<typename T>
void hook(T *original, T detour, const char *name)
{
    LONG err = 0;
    if((err = DetourTransactionBegin()) != NO_ERROR) {
        fprintf(stderr, "DetourTransactionBegin() failed: %ld\n", err);
        _getch();
        exit(1);
    }

    if((err = DetourUpdateThread(GetCurrentThread())) != NO_ERROR) {
        fprintf(stderr, "DetourUpdateThread() failed: %ld\n", err);
        _getch();
        exit(1);
    }

    if((err = DetourAttach((PVOID *)original, (PVOID)detour)) != NO_ERROR) {
        fprintf(stderr, "DetourAttach() failed: %ld\n", err);
        _getch();
        exit(1);
    }

    if((err = DetourTransactionCommit()) != NO_ERROR) {
        fprintf(stderr, "DetourTransactionCommit() failed: %ld\n", err);
        _getch();
        exit(1);
    }

    fprintf(stderr, "Hooked %s (%p -> %p)\n", name, original, detour);
}

WINAPI HANDLE CreateFileA_Hk(LPCSTR lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, LPSECURITY_ATTRIBUTES lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile)
{
    if(!_stricmp(pack_name.c_str(), lpFileName)) {
        if(!pack_file) {
            pack_file = CreateFileA_(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
        }

        return pack_file;
    }

    return CreateFileA_(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes, dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile);
}

WINAPI BOOL CloseHandle_Hk(HANDLE hObject)
{
    if(pack_file == hObject) {
        pack_file = NULL;
    }

    return CloseHandle_(hObject);
}

WINAPI BOOL ReadFile_Hk(HANDLE hFile, LPVOID lpBuffer, DWORD nNumberOfBytesToRead, LPDWORD lpNumberOfBytesRead, LPOVERLAPPED lpOverlapped)
{
    if(hFile == pack_file) {
        LONG pos = SetFilePointer(hFile, 0, NULL, FILE_CURRENT);
        if(pos <= entries_end && nNumberOfBytesToRead == sizeof(pack_entry_t)) {
            /* Attempted to read from header, feed fake values so the engine allocates appropriately. */
            memcpy(lpBuffer, (uint8_t *)fake_pack + pos, nNumberOfBytesToRead);
            *lpNumberOfBytesRead = nNumberOfBytesToRead;
            SetFilePointer(hFile, nNumberOfBytesToRead, NULL, FILE_CURRENT);
            return TRUE;
        } else {
            /* Loop through our patches until we find the appropriate slice. */
            for(size_t i = 0; i < patches.size(); ++i) {
                patch_t *target = &patches[i];

                if(target->start == pos && target->new_length == nNumberOfBytesToRead) {
                    memcpy(lpBuffer, target->data.data(), nNumberOfBytesToRead);
                    *lpNumberOfBytesRead = nNumberOfBytesToRead;
                    SetFilePointer(hFile, target->old_length, NULL, FILE_CURRENT); // XXX: Is this needed?
                    return TRUE;
                }
            }
        }
    }

    return ReadFile_(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead, lpOverlapped);
}

uint32_t crc32(unsigned char *data, int size)
{
    uint32_t r = ~0;
    unsigned char *end = data + size;

    while(data < end) {
        r ^= *data++;

        for(int i = 0; i < 8; i++) {
            uint32_t t = ~((r & 1) - 1); r = (r >> 1) ^ (0xEDB88320 & t);
        }
    }

    return ~r;
}

unsigned char *encrypt(unsigned char *buffer, size_t *size)
{
    BLOWFISH_CTX ctx;
    Blowfish_Init(&ctx, thmj4n_key, sizeof(thmj4n_key));

    size_t new_size = (*size + 7) & ~7;
    if(!(buffer = (unsigned char *)realloc(buffer, new_size))) {
        fprintf(stderr, "Failed to reallocate buffer for blowfish encryption\n");
        _getch();
        exit(1);
    }

    fprintf(stderr, "Resized buffer: %zu -> %zu\n", *size, new_size);
    memset(buffer + *size, 0, new_size - *size);

    size_t half_block = sizeof(unsigned long);
    for(int i = 0; i < *size; i += (2 * half_block)) {
        unsigned long L, R;

        memcpy(&L, &buffer[i], half_block);
        memcpy(&R, &buffer[i + half_block], half_block);
        Blowfish_Encrypt(&ctx, &L, &R);
        memcpy(&buffer[i], &L, half_block);
        memcpy(&buffer[i + half_block], &R, half_block);
    }

    *size = new_size;
    return buffer;
}

void find_override(pack_entry_t *target)
{
    char path[MAX_PATH];
    snprintf(path, MAX_PATH - 1, "%s\\%s", stem_name.c_str(), target->name);

    FILE *fp = fopen(path, "rb");
    if(fp) {
        fprintf(stderr, "Found acceptable override: %s\n", path);

        fseek(fp, 0, SEEK_END);
        size_t fz = ftell(fp);
        fseek(fp, 0, SEEK_SET);

        /* Create a dummy header */
        patch_header_t header = {
            .magic = 0x53535A4C, /* 'LZSS' */
            .size = fz
        };

        /* Construct a new patch */
        patch_t patch;
        memcpy(&patch.name, target->name, sizeof(target->name));
        patch.start = target->start;
        patch.old_length = target->length;
        patch.data.insert(patch.data.end(), (uint8_t *)&header, (uint8_t *)&header + sizeof(patch_header_t));

        /* Encrypt */
        unsigned char *buffer = (unsigned char *)malloc(fz);
        size_t r = fread(buffer, 1, fz, fp);
        if(r != fz) {
            fprintf(stderr, "Attempted to read %zu bytes from %s, read %zu instead\n",
                fz, path, r);
            _getch();
            exit(1);
        }
        fclose(fp);

        buffer = encrypt(buffer, &fz);
        patch.data.insert(patch.data.end(), buffer, buffer + fz);
        patch.new_length = target->length = patch.data.size();
        fprintf(stderr, "Adjusted target length: %u -> %u\n", patch.old_length, patch.new_length);

        uint32_t old_crc = target->crc32_data;
        target->crc32_data = crc32(patch.data.data(), patch.data.size());
        fprintf(stderr, "Adjusted target crc32: 0x%08x -> 0x%08x\n", old_crc, target->crc32_data);

        patches.push_back(patch);
    }
}

void preflight()
{
    char exe_name[MAX_PATH];
    if(!GetModuleFileNameA(NULL, exe_name, MAX_PATH)) {
        fprintf(stderr, "GetModuleFileNameA failed: %ld\n", GetLastError());
        _getch();
        exit(1);
    }

    stem_name = std::filesystem::path(exe_name).stem().string();
    pack_name = "./" + stem_name + ".p";

    /* Parse pack from disk */
    fprintf(stderr, "Parsing pack file: %s\n", pack_name.c_str());

    FILE *fp = fopen(pack_name.c_str(), "rb");
    if(!fp) {
        fprintf(stderr, "Failed to open %s for reading\n", pack_name.c_str());
        _getch();
        exit(1);
    }

    fseek(fp, 0, SEEK_END);
    size_t fz = ftell(fp);
    fseek(fp, 0, SEEK_SET);

    if(fz < sizeof(pack_header_t)) {
        fclose(fp);

        fprintf(stderr, "Likely bogus pack file: %s (size %zu)\n", pack_name.c_str(), fz);
        _getch();
        exit(1);
    }

    pack_header_t header;
    if(fread(&header, sizeof(pack_header_t), 1, fp) != 1) {
        fclose(fp);

        fprintf(stderr, "Failed to read %zu bytes\n", sizeof(pack_header_t));
        _getch();
        exit(1);
    }

    if(memcmp(&header.magic, "PACK", sizeof(header.magic))) {
        fclose(fp);

        fprintf(stderr, "Invalid pack magic: 0x%08x\n", header.magic);
        _getch();
        exit(1);
    }

    size_t entries_size = header.count * sizeof(pack_entry_t);
    fake_pack = (pack_t *)malloc(sizeof(pack_t) + entries_size);
    if(!fake_pack) {
        fclose(fp);

        fprintf(stderr, "Failed to allocate fake pack (%u entries)\n", header.count);
        _getch();
        exit(1);
    }

    fake_pack->header = header;
    for(uint32_t i = 0; i < header.count; ++i) {
        pack_entry_t *target = &fake_pack->entries[i];

        if(fread(target, sizeof(pack_entry_t), 1, fp) != 1) {
            fclose(fp);

            fprintf(stderr, "Failed to read pack entry %u (%zu bytes)\n", i, sizeof(pack_entry_t));
            _getch();
            exit(1);
        }

        find_override(target);
    }

    entries_end = ftell(fp);
    fprintf(stderr, "Pack entries end at offset 0x%08zx\n", entries_end);
    fprintf(stderr, "Loaded %zu patches\n", patches.size());
}

void install_hooks()
{
    hook<CreateFileA_t>(&CreateFileA_, CreateFileA_Hk, "CreateFileA");
    hook<CloseHandle_t>(&CloseHandle_, CloseHandle_Hk, "CloseHandle");
    hook<ReadFile_t>(&ReadFile_, ReadFile_Hk, "ReadFile");
}

BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    switch(fdwReason) {
        case DLL_PROCESS_ATTACH: {
            AllocConsole();
            freopen_s((FILE **)stdout, "CONOUT$", "w", stdout);
            freopen_s((FILE **)stderr, "CONOUT$", "w", stderr);

            preflight();
            install_hooks();
            break;
        }

        case DLL_PROCESS_DETACH: {
            FreeConsole();
            break;
        }
    }

    return TRUE;
}
