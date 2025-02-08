{
  inputs,
  lib,
  lib',
  self,
  ...
}:
let
  nixpkgsArgs = rec {
    config = {
      allowUnfree = true;
      cudaSupport = false;
    };
    overlays = lib.singleton (
      import ../overlays {
        inherit inputs;
        nixpkgsConfig = config;
      }
    );
  };
in
{
  imports = lib'.flocken.getModules ./.;
  systems = lib.singleton "x86_64-linux";
  _module.args = {
    inherit nixpkgsArgs;
  };
  perSystem =
    {
      config,
      system,
      pkgs,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        inherit (nixpkgsArgs) config overlays;
      };
      # the system config should not be built, only evaluated
      checks = lib.removeAttrs config.packages [
        "default"
        "system-config"
      ];
      packages = pkgs.exports // {
        inherit (pkgs) system-manager;
        default = pkgs.system-builder;
        system-config = self.systemConfigs.default.config.build.toplevel;
      };
    };
}
