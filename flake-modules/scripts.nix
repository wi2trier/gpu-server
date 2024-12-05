{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      manager = lib.getExe' pkgs.system-manager "system-manager";
    in
    {
      packages = {
        inherit (pkgs) system-manager setup;
        install = pkgs.writeShellApplication {
          name = "system-manager-rebuild";
          text = ''
            set -x #echo on
            exec ${manager} "''${1:-switch}" --flake ${self} "''${@:2}"
          '';
        };
        uninstall = pkgs.writeShellApplication {
          name = "system-manager-uninstall";
          text = ''
            set -x #echo on
            exec ${manager} deactivate "''$@"
          '';
        };
      };
    };
}
