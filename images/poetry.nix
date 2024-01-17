{
  lib,
  writeShellScriptBin,
  poetry,
  base,
}:
base.override (prev: let
  poetryWrapper = writeShellScriptBin "poetry" ''
    export LD_LIBRARY_PATH="$NIX_LD_LIBRARY_PATH"
    exec ${lib.getExe poetry} "$@"
  '';
in {
  name = "poetry";
  contents = [
    poetryWrapper
  ];
  entrypoint = [(lib.getExe poetryWrapper)];
  env = {
    POETRY_VIRTUALENVS_IN_PROJECT = "1";
  };
})
