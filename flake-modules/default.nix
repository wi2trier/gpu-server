{
  inputs,
  lib,
  lib',
  ...
}:
let
  config = {
    allowUnfree = true;
    cudaSupport = false;
  };
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system config;
    overlays = lib.singleton (import ../overlays { inherit inputs system config; });
  };
in
{
  imports = lib'.flocken.getModules ./.;
  systems = lib.singleton system;
  _module.args = {
    inherit system pkgs;
  };
  perSystem =
    { config, ... }:
    {
      _module.args = {
        inherit pkgs;
      };
      packages.default = config.packages.install;
      checks = config.packages;
    };
}
