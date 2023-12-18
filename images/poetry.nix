{
  lib,
  poetry,
  base,
}:
base.override (prev: {
  name = "poetry";
  contents = [
    poetry
  ];
  entrypoint = [(lib.getExe poetry)];
  env = {
    POETRY_VIRTUALENVS_IN_PROJECT = "1";
  };
})
