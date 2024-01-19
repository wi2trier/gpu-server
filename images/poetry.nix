{
  lib,
  poetry,
  base,
}:
base.override (prev: let
  poetryWrapper = base.passthru.wrapLibraryPath poetry;
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
