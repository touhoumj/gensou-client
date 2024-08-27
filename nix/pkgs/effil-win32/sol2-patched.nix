{ fetchFromGitHub
, stdenvNoCC
, python3
, ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "sol2";
  version = "2.17";

  src = fetchFromGitHub {
    owner = "ThePhD";
    repo = pname;
    rev = "345a398cdc7748427214644bf1606ae4324abb24";
    hash = "sha256-4Y3fmS3f0VKzXoSC0f7TGNvsRt0cUGCBnZY0UyAr7qI=";
  };

  nativeBuildInputs = [
    python3
  ];

  patches = [
    ./fix-new-gcc.patch
  ];

  buildPhase = ''
    python single.py
  '';

  installPhase = ''
    mkdir -p $out/single/sol/
    cp sol.hpp $out/single/sol/
  '';
}
