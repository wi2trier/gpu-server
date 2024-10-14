{
  lib,
  uv,
  base,
}:
let
  uvWrapper = base.passthru.wrapLibraryPath uv;
in
base.override {
  name = "uv";
  contents = [ uvWrapper ];
  entrypoint = [ (lib.getExe uvWrapper) ];
  env = { };
}
