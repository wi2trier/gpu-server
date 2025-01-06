{
  lib,
  config,
  ...
}:
{
  config = lib.mkMerge [
    {
      systemd.services.ollama.wantedBy = lib.mkForce [ "system-manager.target" ];
      systemd.services.ollama-model-loader.wantedBy = lib.mkForce [
        "system-manager.target"
        "ollama.service"
      ];
      systemd.services.open-webui.wantedBy = lib.mkForce [ "system-manager.target" ];
    }
    {
      systemd.services = lib.mapAttrs' (
        _: container:
        lib.nameValuePair container.serviceName {
          wantedBy = lib.mkForce [ "system-manager.target" ];
        }
      ) config.virtualisation.oci-containers.containers;
    }
  ];
}
