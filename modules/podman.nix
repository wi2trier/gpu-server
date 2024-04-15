{ pkgs, lib, ... }:
{
  virtualisation.containers = {
    enable = true;
    registries.search = [ "docker.io" ];
  };

  environment = {
    systemPackages = [
      pkgs.podman
      (pkgs.writeShellApplication {
        name = "docker";
        text = ''
          exec ${lib.getExe pkgs.podman} "$@"
        '';
      })
    ];
  };
}
