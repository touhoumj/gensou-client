# Gensou Client
This repo contains game modifications, tools and build scripts used to modify the Touhou Unreal Mahjong 4N game to use a private server,
located in a separate [Gensou repository](https://github.com/touhoumj/gensou).

**Steps outlined in this document are completely optional, if you just want to play the game.**
**You can find a patched game, configured to use a public instance of the private server, on the /mjg/ repo.**

The client mod is split into two parts:
- Modifications that need to be applied to the game. This goes into the `thmj4n.p` bundle.
- A client library and dependencies the modified game will load. This can be placed in the game's directory without modifying any existing files.

## Obtaining and installing the dependencies
The easiest way is to grab a bundle from GitHub releases.

If you'd like to build it yourself, the best way is to use [nix](https://nixos.org/).
```
nix build .#thmj4n-deps
```

The server address can be configured in the `deps/lua/gensou_config.lua` file.
For convenience, this file can be moved to the game's root directory.

Place the bundle inside game's directory and proceed to the next section, in order to make the game actually it.

## Modifying the game

### Obtaining the game
For the patches to apply cleanly, you need the latest (201408302235) version of the game, with the English patch `01.525` from https://github.com/NicolasTurpin/Touhou-Gensou-Mahjong-4N---ENGLISH-translation/.
Every other step should work regardless of the version used.

### Obtaining the encryption key
Before you can do anything with the game files, you will need the encryption key.
As always, you can find it on the /mjg/ repo.

If you are interested in the process of getting it out of the game yourself, check out [this write-up](key_extraction_writeup.md) (thanks bin).
You are looking for a 56-byte binary blowfish key.

### Extracting game assets
Someone else already created the decryption and extraction tool. Grab a copy [from here](https://github.com/theKeithD/thmj3g-tools/).
It works on 4N too, despite what the repository name may suggest.

Place the encryption key next to the extractor's binaries in a file named `thmj3g.key` and then run:
```
lunpack.exe thmj4n.p -b
```
It will run just fine under 32-bit wine too, if that's what you have.

The extractor will emit files padded with zero bytes, aligned to 8 bytes.
This will cause issues when the source files are loaded back into the game, so it needs to be stripped. You can use a script from this repo to do it.
```
python3 tools/trim_null.py ./thmj4n
```

### Patching the game
Apply the patches from this repo.
```
patch -p1 < 0001-http-client-fix.patch
patch -p1 < 0002-change-server-address.patch
patch -p1 < 0003-unlock-game-features.patch
patch -p1 < 0004-rewrite-the-networking.patch
```

### Load patched files into the game (thanks bin)
Grab a copy of `run_n_gun_32.exe` and `kotldr.dll` from this repo's releases and place it into the game's directory.

Alternatively it can be built with [nix](https://nixos.org/) by running `nix build .#thmj4n-tools`.

Create a new directory called `thmj4n` next to the game's executable and place your modified game source files in it.

Run the game via `run_n_gun_32.exe`, with the dll.
```
run_n_gun_32.exe thmj4n.exe kotldr.dll
```

The game may crash at startup, so this option is meant primarily for development.

For distributing a modified game it's better to create an asset bundle instead.

### Creating a new asset bundle
Encrypt the files.
You can do this by running `blowpack.exe` on every file in your extracted bundle.
Don't accidentally encrypt your entire drive like a baka.
```
fd . ./thmj4n --type file -j 16 -x wine blowpack.exe '{}'
```
Finding a Windows equivalent of this command is left as an exercise for the reader.

Use `LPACK.exe` to create a new bundle.
```
LPACK.exe ./thmj4n
```
This will output a `thmj4n.bin` file. Rename it to `thmj4n.p` and move it into the game directory.

If everything went well, the game should launch without errors and in the top right you should see a message in English, informing that the game is using your private server.
