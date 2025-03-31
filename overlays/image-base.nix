{
  lib,
  dockerTools,
  runCommand,
  writeShellScriptBin,
  git,
  busybox,
  neovim,
  nano,
  zlib,
  stdenv,
  cacert,
  tzdata,
  glibc,
  gcc,
  nix-ld,
}:
rec {
  # https://unix.stackexchange.com/a/415028
  # the existing LD_LIBRARY_PATH is only appended if it is not empty
  exportLibraryPath = ''export LD_LIBRARY_PATH="''${NIX_LD_LIBRARY_PATH}''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}"'';
  wrapLibraryPath =
    pkg:
    writeShellScriptBin (lib.getName pkg) ''
      ${exportLibraryPath}
      exec ${lib.getExe pkg} "$@"
    '';
  build =
    {
      name,
      contents ? [ ],
      entrypoint ? [ "/bin/sh" ],
      cmd ? [ ],
      env ? { },
    }:
    dockerTools.streamLayeredImage {
      inherit name;
      tag = "latest";
      created = "now";
      contents =
        contents
        ++ [
          busybox
          cacert
          git
          nano
          tzdata
          (neovim.override {
            viAlias = true;
            vimAlias = true;
          })
          (lib.getBin glibc)
          (lib.getBin gcc)
          # https://github.com/Mic92/nix-ld/wiki/Using-with-docker-images
          # https://github.com/Mic92/nix-ld/issues/60
          (runCommand "nix-ld" { } ''
            install -D -m755 ${nix-ld}/libexec/nix-ld $out/lib64/$(basename ${stdenv.cc.bintools.dynamicLinker})
          '')
        ]
        ++ (with dockerTools; [
          binSh
          caCertificates
          fakeNss
          usrBinEnv
        ]);
      config = {
        inherit entrypoint cmd;
        env = lib.mapAttrsToList (k: v: "${k}=${v}") (
          {
            NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
              stdenv.cc.cc
              zlib
            ];
            NIX_LD = stdenv.cc.bintools.dynamicLinker;
            SHELL = "/bin/sh";
            PIP_DISABLE_PIP_VERSION_CHECK = "1";
            EDITOR = "nano";
            SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
          }
          // env
        );
      };
    };
}
