{ writeShellScript
, writeText
, zig
, ...
}:

let
  mk_zig = name:
    writeShellScript "${name}" ''
      if [[ ! -z "$NIX_BUILD_TOP" ]]; then
        export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache";
        export ZIG_GLOBAL_CACHE_DIR="$ZIG_LOCAL_CACHE_DIR";
      fi

      ${zig}/bin/zig ${name} "$@"
    '';

  cmake-cross = writeText "x86-windows-gnu.cmake" ''
    # https://raw.githubusercontent.com/starofrainnight/zig-cmake-toolchains

    set(CMAKE_SYSTEM_NAME "Windows")
    set(CMAKE_SYSTEM_PROCESSOR "X86")

    set(CMAKE_C_COMPILER "${mk_zig "cc"}" -target x86-windows-gnu)
    set(CMAKE_CXX_COMPILER "${mk_zig "c++"}" -target x86-windows-gnu)

    set(CMAKE_AR "${mk_zig "ar"}")
    set(CMAKE_RANLIB "${mk_zig "ranlib"}")
  '';
in
cmake-cross
