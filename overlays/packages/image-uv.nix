{
  lib,
  uv,
  imageBase,
}:
let
  uvWrapper = imageBase.wrapLibraryPath uv;
in
imageBase.build {
  name = "uv";
  contents = [ uvWrapper ];
  entrypoint = [ (lib.getExe uvWrapper) ];
  env = { };
}
