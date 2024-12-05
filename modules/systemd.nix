{ lib, pkgs, ... }:
{
  systemd.services = {
    update-system = {
      enable = true;
      startAt = "*-*-* 04:00:00";
      script = ''
        ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server --refresh
      '';
      serviceConfig.Type = "oneshot";
    };
    setup-system = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "system-manager.target" ];
      script = lib.getExe pkgs.setup-system;
    };
  };
}
