{ systemdUtils, unitConfigToText }:
{
  name,
  lib,
  config,
  ...
}:
let
  inherit (systemdUtils.unitOptions) unitOption;
  inherit (lib) mkOption types;
in
{
  options = {
    name = mkOption {
      type = types.str;
      default = name;
    };
    ref = mkOption { readOnly = true; };
    text = mkOption { internal = true; };

    container = mkOption {
      type = types.attrsOf unitOption;
      default = { };
    };
    unit = mkOption {
      type = types.attrsOf unitOption;
      default = { };
    };
    service = mkOption {
      type = types.attrsOf unitOption;
      default = { };
    };
    install = mkOption {
      type = types.attrsOf unitOption;
      default = { };
    };
    quadlet = mkOption {
      type = types.attrsOf unitOption;
      default = { };
    };
  };
  config = {
    ref = "${config.name}.container";
    text = unitConfigToText {
      Container = {
        Name = config.name;
      } // config.container;
      Unit = {
        Description = "Podman container ${config.name}";
      } // config.unit;
      Install = {
        WantedBy = "default.target";
      } // config.install;
      Service = {
        Restart = "always";
        # podman rootless requires "newuidmap" (the suid version, not the non-suid one from pkgs.shadow)
        Environment = "PATH=/usr/bin";
        TimeoutStartSec = 900;
      } // config.service;
      Quadlet = config.quadlet;
    };
  };
}
