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
  environment.systemPackages = lib.singleton (
    pkgs.writeShellApplication {
      name = "apptainer";
      text = ''
        # CUDA_VISIBLE_DEVICES defaults to the sentinel 100 (no GPU); resolve it
        # to a free GPU via findgpu, otherwise honor the user's explicit choice.
        case "''${CUDA_VISIBLE_DEVICES:-100}" in
          100) APPTAINERENV_CUDA_VISIBLE_DEVICES="$(${lib.getExe pkgs.findgpu})" ;;
          *) APPTAINERENV_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES" ;;
        esac
        export APPTAINERENV_CUDA_VISIBLE_DEVICES
        exec ${lib.getExe apptainerOverriden} "$@"
      '';
    }
  );
}
