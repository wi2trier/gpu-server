# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/containers.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.virtualisation.containers;

  inherit (lib) mkOption types;

  toml = pkgs.formats.toml {};
in {
  options.virtualisation.containers = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        This option enables the common /etc/containers configuration module.
      '';
    };

    containersConf.settings = mkOption {
      type = toml.type;
      default = {};
      description = lib.mdDoc "containers.conf configuration";
    };

    storage.settings = mkOption {
      type = toml.type;
      default = {
        storage = {
          driver = "overlay";
          graphroot = "/var/lib/containers/storage";
          runroot = "/run/containers/storage";
        };
      };
      description = lib.mdDoc "storage.conf configuration";
    };

    registries = {
      search = mkOption {
        type = types.listOf types.str;
        default = ["docker.io" "quay.io"];
        description = lib.mdDoc ''
          List of repositories to search.
        '';
      };

      insecure = mkOption {
        default = [];
        type = types.listOf types.str;
        description = lib.mdDoc ''
          List of insecure repositories.
        '';
      };

      block = mkOption {
        default = [];
        type = types.listOf types.str;
        description = lib.mdDoc ''
          List of blocked repositories.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."containers/containers.conf".source =
      toml.generate "containers.conf" cfg.containersConf.settings;

    environment.etc."containers/storage.conf".source =
      toml.generate "storage.conf" cfg.storage.settings;

    environment.etc."containers/registries.conf".source = toml.generate "registries.conf" {
      registries = lib.mapAttrs (n: v: {registries = v;}) cfg.registries;
    };

    environment.etc."containers/policy.json".source = "${pkgs.skopeo.policy}/default-policy.json";
  };
}
