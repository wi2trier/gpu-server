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
        {
          # system-manager only option, NixOS owns every file in /etc anyway
          options.environment.etc = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options.replaceExisting = lib.mkEnableOption "replacing a pre-existing file";
              }
            );
          };
        }
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
