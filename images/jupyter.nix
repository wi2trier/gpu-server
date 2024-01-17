{
  lib,
  writeShellScriptBin,
  python3,
  base,
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

  jupyterArgs = lib.cli.toGNUCommandLineShell {} {
    ip = "0.0.0.0";
    allow-root = true;
    no-browser = true;
    "ServerApp.terminado_settings" = ''shell_command=["/bin/sh"]'';
  };

  entrypoint = writeShellScriptBin "entrypoint" ''
    export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
    ${lib.getExe venvSetup}
    exec ${venvPath}/bin/jupyter lab ${jupyterArgs} "$@"
  '';
in
  base.override (prev: {
    entrypoint = [(lib.getExe entrypoint)];
    env = {
      VIRTUAL_ENV = venvPath;
      PATH = lib.concatStringsSep ":" [
        "${venvPath}/bin"
        "/usr/local/sbin"
        "/usr/local/bin"
        "/usr/sbin"
        "/usr/bin"
        "/sbin"
        "/bin"
      ];
    };
  })
