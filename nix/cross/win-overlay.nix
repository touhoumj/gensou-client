(final: prev: {
  windows = prev.windows.overrideScope (finalScope: prevScope: {
    mingw_w64 = prevScope.mingw_w64.overrideAttrs (oldAttrs: {
      configureFlags = oldAttrs.configureFlags ++ [
        "--with-libraries=winpthreads"
      ];
    });
  });

  threadsCross =
    prev.lib.optionalAttrs prev.targetPlatform.isMinGW {
      model = "posix";
      package = null;
    };

  # Enable lua on Windows. This is bad and makes me sad.
  lua5_1 = prev.lua5_1.overrideAttrs (oldAttrs: {
    makeFlags = [
      "INSTALL_TOP=${placeholder "out"}"
      "INSTALL_MAN=${placeholder "out"}/share/man/man1"
      "R=${oldAttrs.version}"
      "V=${prev.lib.versions.majorMinor oldAttrs.version}"
      "PLAT=mingw"
      "PREFIX=${prev.stdenv.cc.targetPrefix}"
    ];

    patches = [
      ./add-prefix.patch
    ];

    postConfigure = ''
      installFlagsArray=(TO_BIN="lua.exe luac.exe lua51.dll" TO_LIB="liblua.a")
    '';

    meta.platforms = oldAttrs.meta.platforms ++ prev.lib.platforms.windows;
  });
})
