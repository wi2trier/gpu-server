{
  lib,
  dockerTools,
  buildEnv,
  writeShellScriptBin,
  git,
  coreutils,
  neovim,
  nano,
  zlib,
  stdenv,
  python3,
  poetry,
}: let
  setupEnv = ''
    export POETRY_VIRTUALENVS_IN_PROJECT=1
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [stdenv.cc.cc zlib]}:$LD_LIBRARY_PATH"
  '';

  pythonWrapper = writeShellScriptBin "python" ''
    ${setupEnv}
    ${lib.getExe poetry} env use ${lib.getExe python3}
    ${lib.getExe poetry} install --all-extras --no-root --sync
    exec poetry run python "$@"
  '';

  poetryWrapper = writeShellScriptBin "poetry" ''
    ${setupEnv}
    exec ${lib.getExe poetry} "$@"
  '';

  env = buildEnv {
    name = "root-env";
    paths = [
      poetryWrapper
      pythonWrapper
      git
      coreutils
      nano
      neovim
      (writeShellScriptBin "vim" neovim)
      (writeShellScriptBin "vi" neovim)
    ];
    pathsToLink = ["/bin"];
  };
in
  dockerTools.streamLayeredImage {
    name = "poetry";
    tag = "latest";
    created = "now";
    contents = with dockerTools; [
      env
      usrBinEnv
      binSh
      fakeNss
    ];
    config = {
      entrypoint = [(lib.getExe pythonWrapper)];
      cmd = [];
    };
  }
