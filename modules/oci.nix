{ lib, config, ... }:
let
  user = "containers";
  mkContainer =
    attrs@{
      enable,
      labels ? { },
      extraOptions ? [ ],
      ...
    }:
    lib.mkIf enable {
      labels = {
        "io.containers.autoupdate" = "registry";
      } // labels;
      extraOptions = [
        # does not work with gpus, so we override the user below
        # "--userns"
        # "auto"
        "--pull"
        "newer"
      ] ++ extraOptions;
    }
    // (lib.removeAttrs attrs [
      "enable"
      "labels"
      "extraOptions"
    ]);
in
{
  virtualisation.oci-containers.backend = "podman";
  systemd.services = lib.mapAttrs' (
    n: v:
    lib.nameValuePair "${config.virtualisation.oci-containers.backend}-${n}" {
      serviceConfig = {
        User = user;
        Group = user;
      };
    }
  ) config.virtualisation.oci-containers.containers;
  systemd.tmpfiles.settings.oci-containers =
    lib.genAttrs
      [
        "/var/lib/ollama-oci"
        "/var/lib/open-webui-oci"
      ]
      (name: {
        d = {
          user = user;
          group = user;
          mode = "0755";
        };
      });
  virtualisation.oci-containers.containers = {
    ollama = mkContainer {
      enable = false;
      image = "docker.io/ollama/ollama:latest";
      volumes = [
        "/var/lib/ollama-oci:/root/.ollama"
      ];
      extraOptions = [
        "--device"
        "nvidia.com/gpu=all"
      ];
    };
    open-webui = mkContainer {
      enable = false;
      image = "ghcr.io/open-webui/open-webui:latest";
      ports = [
        "3000:8080"
      ];
      volumes = [
        "/var/lib/open-webui-oci:/app/backend/data"
      ];
      extraOptions = [
        "--add-host"
        "host.docker.internal:host-gateway"
      ];
    };
  };
}
