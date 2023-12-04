lib: {
  importFolder = dir: let
    toImport = name: value: dir + ("/" + name);
    filterFiles = name: value:
      !lib.hasPrefix "_" name
      && (
        (value == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
        || value == "directory"
      );
  in
    lib.mapAttrsToList toImport (lib.filterAttrs filterFiles (builtins.readDir dir));
  optionalImport = path:
    if builtins.pathExists path
    then [path]
    else [];
}
