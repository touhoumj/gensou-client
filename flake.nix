{
  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
  };

  outputs = { self, nixpkgs, flake-utils, nix-filter, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        win32Pkgs = pkgs.callPackage ./nix/cross/win32.nix { };

        luajit-win32 = win32Pkgs.callPackage ./nix/pkgs/luajit-win32.nix {
          hostStdenv = pkgs.pkgsi686Linux.stdenv;
        };
        luasocket-win32 = win32Pkgs.callPackage ./nix/pkgs/luasocket-win32.nix { };
        luasec-win32 = win32Pkgs.callPackage ./nix/pkgs/luasec-win32 { luasocket = luasocket-win32; };

        detours = win32Pkgs.callPackage ./nix/pkgs/detours.nix { };

        tools = win32Pkgs.stdenv.mkDerivation {
          pname = "thmj4n-tools";
          version = "1.0.0";

          src = nix-filter {
            root = "${self}/tools";

            include = [
              "CMakeLists.txt"
              (nix-filter.lib.matchExt "c")
              (nix-filter.lib.matchExt "h")
              (nix-filter.lib.matchExt "cpp")
            ];
          };

          nativeBuildInputs = with pkgs; [
            cmake
          ];

          DETOURS_SRC = detours;
        };

        deps = pkgs.stdenv.mkDerivation {
          pname = "thmj4n-deps";
          version = "1.0.0";

          phases = [ "installPhase" ];

          installPhase = ''
            mkdir -p $out/
            mkdir $out/lua

            cp ${luajit-win32}/bin/lua51.dll $out/
            cp ${luasec-win32}/lib/lua/5.1/ssl.dll $out/
            cp -r ${luasec-win32}/share/lua/5.1/* $out/lua/
            cp -r ${luasocket-win32}/lua/5.1/* $out/

            cp ${tools}/bin/libkotldr.dll $out/kotldr.dll
            cp ${tools}/bin/run_n_gun_32.exe $out/
          '';
        };
      in
      {
        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            upx

            python311Packages.pefile
            python311Packages.python
          ];
        };

        packages.default = deps;
      });
}
