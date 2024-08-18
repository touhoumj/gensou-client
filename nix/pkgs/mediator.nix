{ fetchFromGitHub , stdenv }:

stdenv.mkDerivation rec {
  pname = "mediator";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "Olivine-Labs";
    repo = "mediator_lua";
    rev = "ae97959308b462d84d0255f511c8e14cdf06667f";
    hash = "sha256-6UFahaOr/IQlPbocoxmWMM8P6fqjjm/QpzMUMwKABPE=";
  };

  installPhase = ''
    mkdir $out
    cp --no-preserve=mode -r src $out/lua
  '';
}
