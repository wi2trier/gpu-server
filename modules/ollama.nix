# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/virtualization/singularity/generic.nix
{ pkgs, lib, ... }:
let
  wrapper = pkgs.writeShellApplication {
    name = "ollama";
    text = ''
      case "''${CUDA_VISIBLE_DEVICES:-100}" in
        100) CUDA_VISIBLE_DEVICES="$(findgpu)" ;;
      esac
      exec ${lib.getExe pkgs.unstable.ollama} "$@"
    '';
  };
in
{
  environment.systemPackages = [ wrapper ];
}
