{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.virtualisation.quadlet;

  nixosUtils = import "${inputs.nixpkgs}/nixos/lib/utils.nix" { inherit lib config pkgs; };
  systemdUtils = nixosUtils.systemdUtils;

  inherit (lib) mkOption types;

  unitConfigToText =
    unitConfig:
    lib.concatLines (
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
        type = types.attrsOf (
          types.submodule (import ./container.nix { inherit systemdUtils unitConfigToText; })
        );
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
      // lib.mapAttrs' (_: value: {
        name = "containers/systemd/users/990/${value.ref}";
        value = {
          inherit (value) text;
          mode = "0600";
        };
      }) cfg.containers;
  };
}
