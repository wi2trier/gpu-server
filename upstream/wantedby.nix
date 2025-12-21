{
  lib,
  config,
  ...
}:
{
  systemd.services = lib.mkMerge [
    {
      ollama-model-loader.wantedBy = lib.mkForce [
        "system-manager.target"
        "ollama.service"
      ];
    }
    (lib.genAttrs [ "ollama" "open-webui" ] (name: {
      wantedBy = lib.mkForce [ "system-manager.target" ];
    }))
    (lib.mapAttrs' (
      _: container:
      lib.nameValuePair container.serviceName {
        wantedBy = lib.mkForce [ "system-manager.target" ];
      }
    ) config.virtualisation.oci-containers.containers)
  ];
}
