{
  lib,
  writeShellScriptBin,
  poetry,
  base,
}:
base.override (prev: let
  poetryWrapper = writeShellScriptBin "poetry" ''
    ${base.passthru.exportLibraryPath}
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
