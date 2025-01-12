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
    { config, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        inherit (nixpkgsArgs) config overlays;
      };
      checks = lib.removeAttrs config.packages [ "system-manager-config" ];
      packages.system-manager-config = self.systemConfigs.default;
    };
}
