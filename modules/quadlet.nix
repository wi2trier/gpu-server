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
# TODO: Services are not automatically loaded, the following workaround is needed:
# sudo loginctl disable-linger quadlet && sudo loginctl enable-linger quadlet
# TODO: Auto-Update and Pruning do not work currently,
# they are defined as user-services by quadlet-nix which is unsupported by system-manager
# sudo systemctl --machine=quadlet@.host --user status open-webui-quadlet.service
# sudo journalctl _SYSTEMD_USER_UNIT=open-webui-quadlet.service _UID=990
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
          # TODO: Not supported by current podman version
          # AddHost = [
          #   "host.containers.internal:host-gateway"
          # ];
          PodmanArgs = [
            "--add-host=host.containers.internal:host-gateway"
          ];
        };
      };
    };
  };
}
