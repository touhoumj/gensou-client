{ fetchFromGitHub
, lib
, lua5_1
, luasocket
, openssl_3_2
, stdenv
, ...
}:

stdenv.mkDerivation rec {
  pname = "luasec";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "chinponya";
    repo = pname;
    rev = "b8e47f9b8622370ac15d6bc12c6fbb2c49a71b93";
    hash = "sha256-CrRor9PL6+rI8F6cSXQHJUAXpWx8s5vzfpGnMAyIRro=";
  };

  buildInputs = [
    lua5_1
    luasocket
    openssl_3_2
  ];

  buildFlags = [
    "linux"
  ];

  makeFlags = [
    "CMOD=ssl.dll"
    "LUAPATH=${placeholder "out"}/share/lua/5.1"
    "LUACPATH=${placeholder "out"}/lib/lua/5.1"
    "LIBLUA=${lua5_1}/bin/lua51.dll"
  ];

  patches = [
    ./fix-win32.patch
  ];
}
