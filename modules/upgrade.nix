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

  systemd.services.nix-gc = {
    description = "Collect Nix garbage";
    serviceConfig.Type = "oneshot";
    script = ''
      /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 30d
    '';
    startAt = [ "05:00" ];
  };
}
