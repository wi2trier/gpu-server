# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sources by fish built with nix
{
  pkgs,
  lib,
  ...
}: let
  envVars = {
    CUDA_VISIBLE_DEVICES = "100";
    CUDA_DEVICE_ORDER = "PCI_BUS_ID";
  };
in {
  environment.etc = {
    # Make sure that no user uses all GPUs accidentally
    # If device order is not set, nvidia-smi is not consistent with CUDA_VISIBLE_DEVICES
    "profile.d/posix-config.sh".text = lib.concatLines (
      lib.mapAttrsToList
      (name: value: ''
        export ${name}="${value}"
      '')
      envVars
    );
    "fish/config.fish".source = pkgs.writeTextFile {
      name = "config.fish";
      executable = true;
      text =
        ''
          set -gx PATH "/run/system-manager/sw/bin" $PATH
        ''
        + lib.concatLines (
          lib.mapAttrsToList
          (name: value: ''
            set -gx ${name} "${value}"
          '')
          envVars
        );
    };
  };
}
