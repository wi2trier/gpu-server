{
  lib,
  writeShellScriptBin,
  python3,
  base,
  uv,
}:
let
  venvPath = "$PWD/.venv";

  venvSetup = writeShellScriptBin "venv" ''
    if [ -d "${venvPath}" ]; then
      echo "Skipping venv creation, '${venvPath}' already exists"
      echo "Remove '${venvPath}' to force venv recreation with 'rm -rf ${venvPath}'"
    else
      echo "Creating new venv environment in path: '${venvPath}'"
      ${lib.getExe uv} venv --seed ${venvPath}
      ${lib.getExe uv} pip install \
        cbrkit \
        jupyterlab \
        matplotlib \
        nltk \
        numpy \
        openai \
        pandas \
        scikit-learn \
        scipy \
        seaborn \
        sentence-transformers \
        spacy \
        torch \
        transformers \
        ;

    fi
  '';

  jupyterArgs = lib.cli.toGNUCommandLineShell { } {
    ip = "0.0.0.0";
    allow-root = true;
    no-browser = true;
    "ServerApp.terminado_settings" = ''shell_command=["/bin/sh"]'';
  };

  entrypoint = base.passthru.wrapLibraryPath (
    writeShellScriptBin "entrypoint" ''
      ${lib.getExe venvSetup}
      exec ${venvPath}/bin/jupyter lab ${jupyterArgs} "$@"
    ''
  );
in
base.override {
  entrypoint = [ (lib.getExe entrypoint) ];
  contents = [
    python3
    uv
  ];
  env = {
    VIRTUAL_ENV = venvPath;
    UV_PYTHON_PREFERENCE = "only-system";
    PATH = lib.concatStringsSep ":" [
      "${venvPath}/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
    ];
  };
}
