{
  lib,
  inputs,
  self,
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
    nixosModules.default = {
      imports = [
        ../modules
        ../options
      ];
    };
    systemConfigs.default = inputs.system-manager.lib.makeSystemConfig {
      inherit specialArgs;
      # system-manager keeps a top-level overlays argument for recursive cases.
      # nixpkgs.config works as a module option, but nixpkgs.overlays can recurse with overlay functions.
      overlays = [ self.overlays.default ];
      modules = [
        ../modules
        ../options
        ../upstream
        {
          nixpkgs = {
            hostPlatform = "x86_64-linux";
            config = self.nixpkgsConfig;
          };
        }
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
              config = self.nixpkgsConfig;
              overlays = [ self.overlays.default ];
            };
          }
        )
      ];
    };
  };
}
