cmake_minimum_required(VERSION 3.18)
project(thmj4n_tools)
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_BINARY_DIR}")
	message(FATAL_ERROR "Building within the source tree is unsupported")
endif()

if(NOT WIN32)
    message(FATAL_ERROR "thmj4n_tools target win32 only")
endif()

if("$ENV{DETOURS_SRC}" STREQUAL "")
    message(FATAL_ERROR "DETOURS_SRC must point to the detours source tree")
endif()

message(STATUS "$ENV{DETOURS_SRC}")

add_library(kotldr SHARED
    blowfish.c
    kotldr.cpp

    $ENV{DETOURS_SRC}/src/creatwth.cpp
    $ENV{DETOURS_SRC}/src/disolarm.cpp
    $ENV{DETOURS_SRC}/src/disolx64.cpp
    $ENV{DETOURS_SRC}/src/modules.cpp
    $ENV{DETOURS_SRC}/src/detours.cpp
    $ENV{DETOURS_SRC}/src/disolarm64.cpp
    $ENV{DETOURS_SRC}/src/disolx86.cpp
    $ENV{DETOURS_SRC}/src/disasm.cpp
    $ENV{DETOURS_SRC}/src/disolia64.cpp
    $ENV{DETOURS_SRC}/src/image.cpp
)
target_include_directories(kotldr PRIVATE $ENV{DETOURS_SRC}/src/)
target_compile_definitions(kotldr PRIVATE _X86_)
install(TARGETS kotldr)

add_executable(run_n_gun_32 run_n_gun_32.c)
install(TARGETS run_n_gun_32)
