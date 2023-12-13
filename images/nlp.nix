{
  lib,
  dockerTools,
  buildEnv,
  writeShellScriptBin,
  bashInteractive,
  git,
  coreutils,
  neovim,
  nano,
  zlib,
  stdenv,
  python3,
}: let
  venvPath = "./.venv";

  setup-env = writeShellScriptBin "venv" ''
    if [ -d "${venvPath}" ]; then
      echo "Skipping venv creation, '${venvPath}' already exists"
      echo "Remove '${venvPath}' to force venv recreation with 'rm -rf ${venvPath}'"
    else
      echo "Creating new venv environment in path: '${venvPath}'"
      ${python3.interpreter} -m venv "${venvPath}"
      ${venvPath}/bin/pip install \
        "jupyterlab>=4.0,<5" \
        "numpy>=1.24,<2" \
        "scipy>=1.10,<2" \
        "spacy>=3.7,<4" \
        "nltk>=3.8,<4" \
        "torch>=2.1.1,<3" \
        "openai>=1.3,<2" \
        "transformers>=4.34,<5" \
        "sentence-transformers>=2.2,<3"
    fi
  '';

  activateEnv = ''
    ${lib.getExe setup-env}
    source "${venvPath}/bin/activate"
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [stdenv.cc.cc zlib]}:$LD_LIBRARY_PATH"
    export PIP_DISABLE_PIP_VERSION_CHECK=1
  '';

  jupyter = writeShellScriptBin "jupyter" ''
    ${activateEnv}
    exec jupyter lab --ip=0.0.0.0 --allow-root --no-browser --ServerApp.terminado_settings=shell_command=/bin/sh "$@"
  '';

  python = writeShellScriptBin "python" ''
    ${activateEnv}
    exec python "$@"
  '';

  pip = writeShellScriptBin "pip" ''
    ${activateEnv}
    exec pip "$@"
  '';

  env = buildEnv {
    name = "root-env";
    paths = [
      bashInteractive
      python
      pip
      setup-env
      jupyter
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
  dockerTools.buildLayeredImage {
    name = "nlp";
    tag = "v1";
    contents = with dockerTools; [
      env
      usrBinEnv
      binSh
      fakeNss
    ];
    config = {
      entrypoint = [(lib.getExe jupyter)];
      cmd = [];
    };
  }
