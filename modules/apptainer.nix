# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/virtualization/singularity/generic.nix
{ pkgs, lib, ... }:
let
  apptainer = pkgs.writeShellApplication {
    name = "apptainer";
    text = ''
      case "''${CUDA_VISIBLE_DEVICES:-100}" in
        100) APPTAINERENV_CUDA_VISIBLE_DEVICES="$(findgpu)" ;;
        *) APPTAINERENV_CUDA_VISIBLE_DEVICES="$CUDA_VISIBLE_DEVICES" ;;
      esac
      export APPTAINERENV_CUDA_VISIBLE_DEVICES
      exec ${lib.getExe pkgs.apptainer} "$@"
    '';
  };
in
{
  environment = {
    systemPackages = [
      apptainer
      (pkgs.writeShellApplication {
        name = "singularity";
        text = ''
          exec ${lib.getExe apptainer} "$@"
        '';
      })
    ];
  };
}
