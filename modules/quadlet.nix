{ lib, ... }:
let
  containerDefaults = name: {
    container = {
      Pull = "newer";
      AutoUpdate = "registry";
    };
  };

  mkContainer =
    name: containerConfig:
    lib.mkMerge [
      containerDefaults
      containerConfig
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
    enable = false;
    containers = lib.mapAttrs mkContainer {
      ollama = {
        container = {
          Image = "docker.io/ollama/ollama:latest";
          Volume = [
            "/var/lib/ollama-quadlet:/root/.ollama:U"
          ];
          AddDevice = [
            "nvidia.com/gpu=all"
          ];
        };
      };
      open-webui = {
        container = {
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
