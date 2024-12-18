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
        n: v:
        lib.nameValuePair "${config.virtualisation.oci-containers.backend}-${n}" {
          wantedBy = lib.mkForce [ "system-manager.target" ];
        }
      ) config.virtualisation.oci-containers.containers;
    }
  ];
}
