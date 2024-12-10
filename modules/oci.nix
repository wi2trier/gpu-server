{ lib, ... }:
let
  mkContainer =
    attrs@{
      labels ? { },
      extraOptions ? [ ],
      ...
    }:
    {
      labels = {
        "io.containers.autoupdate" = "registry";
      } // labels;
      extraOptions = [
        "--userns"
        "auto"
        "--pull"
        "newer"
      ] ++ extraOptions;
    }
    // (lib.removeAttrs attrs [
      "labels"
      "extraOptions"
    ]);
in
{
  systemd.tmpfiles.settings.oci-containers = {
    "/var/lib/ollama-oci".d = {
      user = "containers";
      group = "containers";
    };
    "/var/lib/open-webui-oci".d = {
      user = "containers";
      group = "containers";
    };
  };
  virtualisation.oci-containers.containers = {
    # ollama = mkContainer {
    #   image = "docker.io/ollama/ollama:latest";
    #   volumes = [
    #     "/var/lib/ollama-oci:/root/.ollama"
    #   ];
    #   extraOptions = [
    #     "--device"
    #     "nvidia.com/gpu=4,5,6,7"
    #   ];
    # };
    # open-webui = mkContainer {
    #   image = "ghcr.io/open-webui/open-webui:latest";
    #   ports = [
    #     "3000:8080"
    #   ];
    #   volumes = [
    #     "/var/lib/open-webui-oci:/app/backend/data"
    #   ];
    #   extraOptions = [
    #     "--add-host"
    #     "host.docker.internal:host-gateway"
    #   ];
    # };
  };
}
