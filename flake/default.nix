{
  inputs,
  lib,
  lib',
  self,
  ...
}:
let
  nixpkgsArgs = {
    config = self.nixpkgsConfig;
    overlays = lib.singleton self.overlays.default;
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
        inherit (pkgs) system-manager nix-update;
        system-config = self.systemConfigs.default.config.build.toplevel;
      };
      apps.default.program = pkgs.writeShellApplication {
        name = "system-manager";
        text = ''
          ${lib.getExe' pkgs.system-manager "system-manager"} "$@" --flake ${self.outPath}
        '';
      };
    };
  flake = {
    nixpkgsConfig = {
      allowUnfree = true;
      cudaSupport = false;
      # Build CUDA packages natively for the server's Tesla V100 (sm_70), which
      # nixpkgs omits from its defaults. Native SASS avoids a load-time PTX JIT
      # that the hardened llama-cpp service (MemoryDenyWriteExecute) would block.
      cudaCapabilities = [ "7.0" ];
    };
    overlays.default = import ../overlays {
      inherit inputs;
      inherit (self) nixpkgsConfig;
    };
  };
}
