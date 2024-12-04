# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/virtualization/singularity/generic.nix
{ pkgs, lib, ... }:
let
  ollamaWrapper = pkgs.writeShellApplication {
    name = "ollama";
    text = ''
      case "''${CUDA_VISIBLE_DEVICES:-100}" in
        100) CUDA_VISIBLE_DEVICES="$(findgpu)" ;;
      esac
      exec ${lib.getExe pkgs.ollama} "$@"
    '';
  };
in
{
  environment.systemPackages = [ ollamaWrapper ];
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
