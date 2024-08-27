{ callPackage
, cmake
, fetchFromGitHub
, lua5_1
, ninja
, stdenv
, ...
}:

let
  sol2-patched = callPackage ./sol2-patched.nix { };
in
stdenv.mkDerivation rec {
  pname = "effil";
  version = "1.2-0";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-nxtgmRirR6hXQTxzFI3xki3oOT7AlHUkyvXTh3QdMmY=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  cmakeFlags = [
    "-DLUA_INCLUDE_DIR=${lua5_1}/include"
    "-DLUA_LIBRARY=${lua5_1}/bin/lua51.dll"
  ];

  patchPhase = ''
    rm -r libs/sol
    cp -r --no-preserve=mode ${sol2-patched} libs/sol
  '';
}
