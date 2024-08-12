{ pkgs, system }:

import pkgs.path {
  inherit system;
  crossSystem = pkgs.lib.systems.examples.mingw32 // { isStatic = true; };

  overlays = [
    (import ./win-overlay.nix)
  ];
}
