{ fetchFromGitHub
, lua5_1
, stdenv
, ...
}:

stdenv.mkDerivation rec {
  pname = "luasocket";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "lunarmodules";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-sKSzCrQpS+9reN9IZ4wkh4dB50wiIfA87xN4u1lyHo4=";
  };

  buildInputs = [
    lua5_1
  ];

  makeFlags = [
    "prefix=${placeholder "out"}"
    "PLAT=mingw"
    "CC=${stdenv.cc.targetPrefix}gcc"
    "LD=${stdenv.cc.targetPrefix}gcc"
    "LUAINC_mingw=${lua5_1}/include"
    "LUALIB_mingw=${lua5_1}/bin/lua51.dll"
  ];
}
