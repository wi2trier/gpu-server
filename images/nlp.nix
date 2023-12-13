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
}: let
  venvPath = "./.venv";

  venvSetup = writeShellScriptBin "venv" ''
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

  venvCmd = name: args:
    writeShellScriptBin name ''
      ${lib.getExe venvSetup}
      source "${venvPath}/bin/activate"
      export LD_LIBRARY_PATH="${lib.makeLibraryPath [stdenv.cc.cc zlib]}:$LD_LIBRARY_PATH"
      export PIP_DISABLE_PIP_VERSION_CHECK=1
      exec ${name} ${args} "$@"
    '';

  venvJupyter = venvCmd "jupyter" "lab --ip=0.0.0.0 --allow-root --no-browser --ServerApp.terminado_settings=shell_command=/bin/sh";

  env = buildEnv {
    name = "root-env";
    paths = [
      venvSetup
      (venvCmd "python" "")
      (venvCmd "pip" "")
      venvJupyter
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
      entrypoint = [(lib.getExe venvJupyter)];
      cmd = [];
    };
  }
