{
  lib,
  poetry,
  imageBase,
}:
let
  poetryWrapper = imageBase.wrapLibraryPath poetry;
in
imageBase.build {
  name = "poetry";
  contents = [ poetryWrapper ];
  entrypoint = [ (lib.getExe poetryWrapper) ];
  env = {
    POETRY_VIRTUALENVS_IN_PROJECT = "1";
  };
}
