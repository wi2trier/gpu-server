{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.virtualisation.podman;
in
# TODO: Add support for auto-prune
{
  options = {
    virtualisation.podman = {
      enable = lib.mkEnableOption "podman";
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.podman;
        internal = true;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.package
      (pkgs.writeShellApplication {
        name = "docker";
        text = ''
          exec ${lib.getExe cfg.package} "$@"
        '';
      })
    ];
  };
}
