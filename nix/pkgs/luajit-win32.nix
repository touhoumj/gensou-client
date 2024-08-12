{ fetchFromGitHub
, lib
, stdenv
, hostStdenv
, ...
}:

stdenv.mkDerivation rec {
  pname = "LuaJIT";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = pname;
    repo = pname;
    rev = "v${version}";
    hash = "sha256-iN7g0UOmTWZjamxpRVC2S+f6PgPbbGGQEzuKaD+rjx8=";
  };

  makeFlags = [
    "PREFIX=${placeholder "out"}"
    "CROSS=${stdenv.cc.targetPrefix}"
    "HOST_CC=${hostStdenv.cc}/bin/cc"
    "TARGET_SYS=${stdenv.hostPlatform.uname.system}"
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp src/lua51.dll $out/bin/
  '';
}
