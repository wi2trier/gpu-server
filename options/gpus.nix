{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.gpu-server.gpus = {
    reserved = mkOption {
      type = types.listOf types.ints.unsigned;
      default = [ ];
      description = "Indices of the GPUs that only members of `group` can open.";
    };
    group = mkOption {
      type = types.str;
      default = "gpu-reserved";
      readOnly = true;
      description = "Group owning the reserved GPUs.";
    };
  };
}
