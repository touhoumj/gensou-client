#https://raw.githubusercontent.com/starofrainnight/zig-cmake-toolchains

set(CMAKE_SYSTEM_NAME "Windows")
set(CMAKE_SYSTEM_PROCESSOR "X86")

set(CMAKE_C_COMPILER "${CMAKE_CURRENT_LIST_DIR}/cc" -target x86-windows-gnu)
set(CMAKE_CXX_COMPILER "${CMAKE_CURRENT_LIST_DIR}/c++" -target x86-windows-gnu)

set(CMAKE_AR "${CMAKE_CURRENT_LIST_DIR}/ar")
set(CMAKE_RANLIB "${CMAKE_CURRENT_LIST_DIR}/ranlib")
