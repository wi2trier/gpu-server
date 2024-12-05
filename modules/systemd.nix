{ lib, pkgs, ... }:
{
  systemd.services = {
    system-update = {
      enable = true;
      startAt = "*-*-* 04:00:00";
      script = ''
        ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server --refresh
      '';
      serviceConfig.Type = "oneshot";
    };
    system-setup = {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "system-manager.target" ];
      script = lib.getExe pkgs.system-setup;
    };
  };
}
