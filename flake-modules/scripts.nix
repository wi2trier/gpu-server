{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      manager = lib.getExe' pkgs.system-manager "system-manager";
    in
    {
      packages = {
        inherit (pkgs) system-manager system-setup;
        system-install = pkgs.writeShellApplication {
          name = "system-install";
          text = ''
            set -x #echo on
            exec ${manager} "''${1:-switch}" --flake ${self} "''${@:2}"
          '';
        };
        system-uninstall = pkgs.writeShellApplication {
          name = "system-uninstall";
          text = ''
            set -x #echo on
            exec ${manager} deactivate "''$@"
          '';
        };
      };
    };
}
