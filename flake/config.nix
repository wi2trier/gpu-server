{
  lib,
  inputs,
  self,
  lib',
  nixpkgsArgs,
  ...
}:
let
  specialArgs = {
    inherit inputs self lib';
  };
in
{
  flake = {
    nixosModules.default = {
      imports = [
        ../modules
        ../options
      ];
    };
    systemConfigs.default = inputs.system-manager.lib.makeSystemConfig {
      extraSpecialArgs = specialArgs;
      modules = [
        ../modules
        ../options
        ../upstream
        (
          { lib, config, ... }:
          {
            nixpkgs = {
              hostPlatform = "x86_64-linux";
              # does not work due to infinite recursion
              # inherit (nixpkgsArgs) config overlays;
            };
            _module.args.pkgs = lib.mkForce (
              import inputs.nixpkgs {
                system = config.nixpkgs.hostPlatform;
                inherit (nixpkgsArgs) config overlays;
              }
            );
          }
        )
      ];
    };
    nixosConfigurations.default = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../modules
        ../options
        (
          { modulesPath, ... }:
          {
            # use virtual machine profile, otherwise file systems need to be defined
            imports = [ "${modulesPath}/virtualisation/qemu-vm.nix" ];
            system.stateVersion = lib.trivial.release;
            nixpkgs = {
              hostPlatform = "x86_64-linux";
              inherit (nixpkgsArgs) config overlays;
            };
          }
        )
      ];
    };
  };
}
