{ lib, ... }:
let
  containerDefaults = {
    uid = 990;
    containerConfig = {
      Pull = "newer";
      AutoUpdate = "registry";
    };
    serviceConfig = {
      ExecSearchPath = [ "/usr/bin" ];
    };
    installConfig = {
      WantedBy = [ "system-manager.target" ];
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
        d.user = "quadlet";
      });
  virtualisation.quadlet = {
    enable = true;
    containers = lib.mapAttrs mkContainer {
      ollama-quadlet = {
        containerConfig = {
          Image = "docker.io/ollama/ollama:latest";
          Volume = [
            "/var/lib/ollama-quadlet:/root/.ollama"
          ];
          AddDevice = [
            "nvidia.com/gpu=all"
          ];
        };
      };
      open-webui-quadlet = {
        containerConfig = {
          Image = "ghcr.io/open-webui/open-webui:latest";
          PublishPort = [
            "3000:8080"
          ];
          Volume = [
            "/var/lib/open-webui-quadlet:/app/backend/data"
          ];
          # TODO: Not supported by current podman version
          # AddHost = [
          #   "host.docker.internal:host-gateway"
          # ];
          PodmanArgs = [
            "--add-host=host.containers.internal:host-gateway"
          ];
        };
      };
    };
  };
}
