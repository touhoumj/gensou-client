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
        zig-cross = pkgs.callPackage ./nix/pkgs/zig-cross.nix { };
        detours = win32Pkgs.callPackage ./nix/pkgs/detours.nix { };
      in
      {
        packages.effil-win32 =
          win32Pkgs.callPackage ./nix/pkgs/effil-win32.nix {
            inherit zig-cross;
          };

        packages.luajit-win32 =
          win32Pkgs.callPackage ./nix/pkgs/luajit-win32.nix {
            hostStdenv = pkgs.pkgsi686Linux.stdenv;
          };

        packages.luasocket-win32 =
          win32Pkgs.callPackage ./nix/pkgs/luasocket-win32.nix { };

        packages.luasec-win32 = win32Pkgs.callPackage ./nix/pkgs/luasec-win32 {
          luasocket = self.packages.${system}.luasocket-win32;
        };

        packages.lua-cbor = pkgs.callPackage ./nix/pkgs/lua-cbor.nix { };

        packages.mediator = pkgs.callPackage ./nix/pkgs/mediator.nix { };

        packages.lua-websockets =
          pkgs.callPackage ./nix/pkgs/lua-websockets.nix { };

        packages.gensou = pkgs.stdenv.mkDerivation {
          pname = "gensou";
          version = "0.1.0";

          src = nix-filter {
            root = "${self}/src";
          };

          phases = [ "installPhase" ];

          installPhase = ''
            mkdir $out
            cp --no-preserve=mode -r . $out/lua
          '';
        };

        packages.thmj4n-tools = pkgs.stdenv.mkDerivation {
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

          nativeBuildInputs = with pkgs; [ cmake zig ];

          cmakeFlags = [
            "-DCMAKE_TOOLCHAIN_FILE=${zig-cross}"
          ];

          postInstall = ''
            find $out/ -type f \( -name '*.dll' -o -name '*.exe' \) \
              -exec strip {} \;
          '';

          DETOURS_SRC = detours;
        };

        packages.thmj4n-deps = pkgs.stdenv.mkDerivation {
          pname = "thmj4n-deps";
          version = "1.0.0";

          phases = [ "installPhase" ];

          installPhase = with self.packages.${system}; ''
            mkdir -p $out/deps/lua

            cp --no-preserve=mode ${luajit-win32}/bin/lua51.dll $out/
            cp --no-preserve=mode ${effil-win32}/effil.dll $out/deps/
            cp --no-preserve=mode ${luasec-win32}/lib/lua/5.1/ssl.dll $out/deps/
            cp --no-preserve=mode -r ${luasec-win32}/share/lua/5.1/* $out/deps/lua/
            cp --no-preserve=mode -r ${luasocket-win32}/lua/5.1/* $out/deps/
            cp --no-preserve=mode -r ${lua-cbor}/lua/* $out/deps/lua/
            cp --no-preserve=mode -r ${mediator}/lua/* $out/deps/lua/
            cp --no-preserve=mode -r ${lua-websockets}/lua/* $out/deps/lua/
            cp --no-preserve=mode -r ${gensou}/lua/* $out/deps/lua/

            find $out/ -type f \( -name '*.dll' -o -name '*.exe' \) \
              -exec strip {} \;
          '';
        };

        packages.default = self.packages.${system}.thmj4n-deps;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            cmake
            ninja
            upx
            zig

            python311Packages.pefile
            python311Packages.python
          ];

          DETOURS_SRC = detours;
          CMAKE_TOOLCHAIN = zig-cross;
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
