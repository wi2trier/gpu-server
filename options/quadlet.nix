{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.virtualisation.quadlet;

  inherit (lib) mkOption types;
  inherit (systemdUtils.unitOptions) unitOption;

  nixosUtils = import "${inputs.nixpkgs}/nixos/lib/utils.nix" { inherit lib config pkgs; };
  systemdUtils = nixosUtils.systemdUtils;
  unitOptions = types.attrsOf unitOption;

  unitConfigToText =
    unitConfig:
    lib.concatStringsSep "\n\n" (
      lib.mapAttrsToList (name: value: ''
        [${name}]
        ${systemdUtils.lib.attrsToSection value}
      '') unitConfig
    );
in
{
  options = {
    virtualisation.quadlet = {
      enable = lib.mkEnableOption "quadlet";
      containers = mkOption {
        type = types.attrsOf unitOptions;
        default = { };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    environment.etc =
      {
        "systemd/user-generators/podman-user-generator" = {
          source = "${pkgs.podman}/lib/systemd/user-generators/podman-user-generator";
        };
      }
      // lib.mapAttrs' (name: value: {
        name = "containers/systemd/users/990/${name}.container";
        value = {
          text = unitConfigToText value;
          mode = "0600";
        };
      }) cfg.containers;
  };
}
