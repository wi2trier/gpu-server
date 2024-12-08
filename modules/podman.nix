{ pkgs, lib, ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/containers.nix
  virtualisation.containers = {
    enable = true;
    ociSeccompBpfHook.enable = false;
    containersConf = {
      cniPlugins = lib.mkForce [ ];
      settings = lib.mkForce { };
    };
    registries.search = [ "docker.io" ];
  };
  virtualisation.podman.enable = true;
}
