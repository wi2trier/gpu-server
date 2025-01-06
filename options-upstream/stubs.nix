{
  lib,
  ...
}:
{
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
}
