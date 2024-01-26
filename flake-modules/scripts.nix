{
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages = {
      manager = lib.getExe pkgs.system-manager;
      install = pkgs.writeShellApplication {
        name = "system-manager-rebuild";
        text = ''
          set -x #echo on
          exec ${lib.getExe pkgs.system-manager} "''${1:-switch}" --flake ${self} "''${@:2}"
        '';
      };
      uninstall = pkgs.writeShellApplication {
        name = "system-manager-uninstall";
        text = ''
          set -x #echo on
          exec ${lib.getExe pkgs.system-manager} deactivate "''$@"
        '';
      };
      setup = pkgs.writeShellApplication {
        name = "system-manager-setup";
        text = ''
          # only root possible
          if [ "$(id -u)" -ne 0 ]; then
            echo "This script must be run as root" >&2
            exit 1
          fi
          set -x #echo on
          # set up nix
          cp -f ${../etc/nix.conf} /etc/nix/nix.conf
          systemctl restart nix-daemon
          # set up cuda support for oci engines like podman
          nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
          chmod -R 755 /etc/cdi
          # set compute mode to exclusive process (https://stackoverflow.com/a/50056586)
          nvidia-smi -c 3
          # disable default motd
          chmod -x /etc/update-motd.d/*
        '';
      };
    };
  };
}
