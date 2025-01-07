{ lib, ... }:
let
  mkDefaults = name: {
    Container = {
      Name = name;
      Pull = "newer";
      AutoUpdate = "registry";
    };
    Unit = {
      Description = "Podman container ${name}";
    };
    Service = {
      Restart = "always";
      Environment = "PATH=/usr/bin";
      TimeoutStartSec = 900;
    };
    Install = {
      WantedBy = "system-manager.target";
    };
  };

  mkContainer =
    name: mkConfig:
    lib.mkMerge [
      (mkConfig name)
      (mkDefaults name)
    ];
in
{
  systemd.tmpfiles.settings.quadlet =
    lib.genAttrs
      [
        "/var/lib/ollama-quadlet"
        "/var/lib/open-webui-quadlet"
      ]
      (name: {
        d.mode = "0755";
      });
  virtualisation.quadlet = {
    enable = true;
    containers = lib.mapAttrs mkContainer {
      ollama = name: {
        Container = {
          Image = "docker.io/ollama/ollama:latest";
          Volume = [
            "/var/lib/ollama-quadlet:/root/.ollama:U"
          ];
          AddDevice = [
            "nvidia.com/gpu=all"
          ];
        };
      };
      open-webui = name: {
        Container = {
          Image = "ghcr.io/open-webui/open-webui:latest";
          PublishPort = [
            "3000:8080"
          ];
          Volume = [
            "/var/lib/open-webui-quadlet:/app/backend/data:U"
          ];
          AddHost = [
            "host.docker.internal:host-gateway"
          ];
        };
      };
    };
  };
}
