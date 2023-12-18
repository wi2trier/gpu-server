{
  lib,
  dockerTools,
  git,
  busybox,
  vim,
  nano,
  zlib,
  stdenv,
  cacert,
  tzdata,
  name ? "base",
  contents ? [],
  entrypoint ? [],
  cmd ? [],
  env ? {},
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
      vim
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
        LD_LIBRARY_PATH = lib.makeLibraryPath [stdenv.cc.cc zlib];
        SHELL = "/bin/sh";
        PIP_DISABLE_PIP_VERSION_CHECK = "1";
      }
      // env
    );
  };
}
