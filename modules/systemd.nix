{ lib, pkgs, ... }:
{
  systemd.services = {
    system-update = {
      enable = true;
      startAt = "*-*-* 04:00:00";
      script = ''
        ${lib.getExe pkgs.nix} upgrade-nix
        ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server --refresh
        ${lib.getExe pkgs.podman} auto-update
      '';
      serviceConfig.Type = "oneshot";
      after = [ "network.target" ];
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
