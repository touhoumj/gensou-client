{ fetchFromGitHub, stdenv }:

stdenv.mkDerivation rec {
  pname = "lua-cbor";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Zash";
    repo = pname;
    rev = "c48d21239ddb463440b878d2e93f1e3720e8dcc1";
    hash = "sha256-AJj9Wqi2yMn6aWc5n++O7p9I+PmKtx4nk/N24LcsD80=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/lua
    cp --no-preserve=mode -r $src/*.lua $out/lua
  '';
}
