{ lib, pkgs, ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/containers.nix
  virtualisation.containers = {
    enable = true;
    ociSeccompBpfHook.enable = false;
    containersConf = {
      cniPlugins = lib.mkForce [ ];
      settings = lib.mkForce {
        engine = {
          compose_providers = [ (lib.getExe pkgs.podman-compose) ];
          compose_warning_logs = false;
        };
      };
    };
    registries.search = [ "docker.io" ];
  };
  virtualisation.podman.enable = true;
  environment.systemPackages = with pkgs; [ podman-compose ];
}
