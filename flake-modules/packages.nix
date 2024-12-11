{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs)
          system-manager
          system-setup
          findgpu
          userctl
          build-apptainer
          build-container
          ollama
          ;
        default = pkgs.writeShellApplication {
          name = "gpu-server";
          text = ''
            set -x #echo on
            ${lib.getExe' pkgs.system-manager "system-manager"} "''${1:-switch}" --flake ${self} "''${@:2}"
            ${lib.getExe pkgs.system-setup}
          '';
        };
      };
    };
}
