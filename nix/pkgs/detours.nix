{ fetchFromGitHub
, stdenvNoCC
, ...
}:

stdenvNoCC.mkDerivation {
  pname = "detours";
  version = "4.0.1";

  src = fetchFromGitHub {
    owner = "Microsoft";
    repo = "Detours";
    rev = "4b8c659f549b0ab21cf649377c7a84eb708f5e68";
    hash = "sha256-d/AKgPJ/kdFktdwNjUO6R5+cZTAyDDaUQQ/tVCiiWPA=";
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir $out
    cp -r $src/* $out/
  '';
}
