{
  lib,
  lib',
  nixosModulesPath,
  config,
  ...
}:
{
  imports = [
    "${nixosModulesPath}/services/misc/ollama.nix"
    "${nixosModulesPath}/services/misc/open-webui.nix"
    "${nixosModulesPath}/virtualisation/containers.nix"
    "${nixosModulesPath}/virtualisation/oci-containers.nix"
  ] ++ (lib'.flocken.getModules ./.);
  options = {
    networking.firewall = lib.mkOption {
      internal = true;
      default = { };
      type = lib.types.attrs;
    };
    networking.proxy.envVars = lib.mkOption {
      internal = true;
      default = { };
      type = lib.types.attrs;
    };
    virtualisation.docker = lib.mkOption {
      internal = true;
      default = { };
      type = lib.types.attrs;
    };
  };
  config = lib.mkMerge [
    {
      systemd.services.ollama.wantedBy = lib.mkForce [ "system-manager.target" ];
      systemd.services.ollama-model-loader.wantedBy = lib.mkForce [
        "system-manager.target"
        "ollama.service"
      ];
      systemd.services.open-webui.wantedBy = lib.mkForce [ "system-manager.target" ];
      virtualisation.oci-containers.backend = "podman";
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
