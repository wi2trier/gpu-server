{
  lib,
  poetry,
  base,
}: let
  poetryWrapper = base.passthru.wrapLibraryPath poetry;
in
  base.override {
    name = "poetry";
    contents = [
      poetryWrapper
    ];
    entrypoint = [(lib.getExe poetryWrapper)];
    env = {
      POETRY_VIRTUALENVS_IN_PROJECT = "1";
    };
  }
