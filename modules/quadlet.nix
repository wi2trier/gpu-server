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
    # installConfig.WantedBy not needed because it depends on default.target due to uid setting
  };

  mkContainer =
    name: containerConfig:
    lib.mkMerge [
      containerDefaults
      containerConfig
    ];
in
# TODO: Auto-Update and Pruning do not work currently, they are defined as user-services by quadlet-nix which is unsupported by system-manager

# Commands to manage user services:
# sudo systemctl --machine=quadlet@ --user status NAME.service
# sudo journalctl _UID=990 _SYSTEMD_USER_UNIT=NAME.service
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
    enable = false;
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
        };
      };
    };
  };
}
