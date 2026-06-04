{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:wi2trier/gpu-server";
    dates = "04:00";
  };

  systemd.services.upgrade-nix = {
    description = "Upgrade Nix";
    serviceConfig.Type = "oneshot";
    script = ''
      /nix/var/nix/profiles/default/bin/nix upgrade-nix
    '';
    startAt = [ "03:00" ];
  };
}
