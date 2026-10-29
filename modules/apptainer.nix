# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/virtualization/singularity/generic.nix
{ pkgs, lib, ... }:
let
  apptainerOverriden = pkgs.apptainer.override {
    enableNvidiaContainerCli = false;
    forceNvcCli = false;
    systemBinPaths = [ "/usr/bin" ];
  };
in
{
  environment.systemPackages = lib.singleton (pkgs.findgpu.wrap apptainerOverriden);
}
