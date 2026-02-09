{
  lib,
  ...
}:
let
  stubOption = lib.mkOption {
    internal = true;
    default = { };
    type = with lib.types; attrsOf anything;
  };
in
{
  options = {
    networking.proxy.envVars = stubOption;
    virtualisation.docker = stubOption;
    systemd.user = stubOption;
  };
}
