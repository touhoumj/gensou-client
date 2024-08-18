{ fetchFromGitHub , stdenv }:

stdenv.mkDerivation rec {
  pname = "lua-websockets";
  version = "2.2";

  src = fetchFromGitHub {
    owner = "lipp";
    repo = pname;
    rev = "1c6e94b27fe7cb157877987fba86299fb326be0c";
    hash = "sha256-79qjhfzQHMwr1LG0fJcgEdQykLeAgHEhs7M0VhQK/qo=";
  };

  installPhase = ''
    mkdir $out
    cp --no-preserve=mode -r src $out/lua
  '';
}
