{
  inputs,
  lib,
  lib',
  ...
}:
let
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
    overlays = lib.singleton (
      final: prev: {
        apptainer = prev.apptainer.override {
          enableNvidiaContainerCli = false;
          forceNvcCli = false;
        };
        system-manager = inputs.system-manager.packages.${system}.default;
        nixglhost = inputs.nixglhost.packages.${system}.default;
        stable = prev;
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        };
        inherit (final.unstable) uv;
      }
    );
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
