{ fetchFromGitHub
, lib
, lua5_1
, luasocket
, openssl
, stdenv
, ...
}:

stdenv.mkDerivation rec {
  pname = "luasec";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "lunarmodules";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-o3uiZQnn/ID1qAgpZAqA4R3fWWk+Ajcgx++iNu1yLWc=";
  };

  buildInputs = [
    lua5_1
    luasocket
    openssl
  ];

  buildFlags = [
    "linux"
  ];

  makeFlags = [
    "CMOD=ssl.dll"
    "LUAPATH=${placeholder "out"}/share/lua/5.1"
    "LUACPATH=${placeholder "out"}/lib/lua/5.1"
  ];

  patches = [
    ./fix-win32.patch
  ];
}
