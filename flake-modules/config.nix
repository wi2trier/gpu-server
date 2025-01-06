{
  lib,
  inputs,
  self,
  pkgs,
  system,
  lib',
  ...
}:
let
  specialArgs = {
    inherit inputs self lib';
  };
in
{
  flake = {
    systemConfigs.default = inputs.system-manager.lib.makeSystemConfig {
      extraSpecialArgs = specialArgs;
      modules = [
        ../modules
        ../options-upstream
        {
          _module.args.pkgs = lib.mkForce pkgs;
          nixpkgs.hostPlatform = system;
        }
      ];
    };
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit system pkgs specialArgs;
      modules = [
        ../modules
        (
          { modulesPath, ... }:
          {
            # use virtual machine profile, otherwise file systems need to be defined
            imports = [ "${modulesPath}/virtualisation/lxc-container.nix" ];
            system.stateVersion = lib.trivial.release;
          }
        )
      ];
    };
  };
}
