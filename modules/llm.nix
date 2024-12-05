# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/virtualization/singularity/generic.nix
{ pkgs, lib, ... }:
{
  environment.systemPackages = lib.singleton (pkgs.mkCudaWrapper pkgs.ollama);
  services.ollama = {
    enable = true;
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "4,5,6,7";
    };
  };
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8000;
  };
}
