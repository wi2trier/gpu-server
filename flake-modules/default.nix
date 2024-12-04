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
      cudaSupport = false;
    };
    overlays = lib.singleton (
      final: prev: {
        apptainer = prev.apptainer.override {
          enableNvidiaContainerCli = false;
          forceNvcCli = false;
        };
        ollama = final.unstable.ollama.override {
          acceleration = "cuda";
        };
        system-manager = inputs.system-manager.packages.${system}.default;
        nixglhost = inputs.nixglhost.packages.${system}.default;
        stable = prev;
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = false;
          };
        };
        inherit (final.unstable) uv open-webui;
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
