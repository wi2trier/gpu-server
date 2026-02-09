# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sources by fish built with nix
{ pkgs, lib, ... }:
let
  envVars = {
  };
in
{
  environment.etc = {
    # Make sure that no user uses all GPUs accidentally
    # If device order is not set, nvidia-smi is not consistent with CUDA_VISIBLE_DEVICES
    "profile.d/posix-config.sh".text = ''
      export CUDA_VISIBLE_DEVICES="100"
      export CUDA_DEVICE_ORDER="PCI_BUS_ID"
    '';
    "fish/config.fish".text = ''
      fish_add_path "/run/system-manager/sw/bin"
      set -gx CUDA_VISIBLE_DEVICES "100"
      set -gx CUDA_DEVICE_ORDER "PCI_BUS_ID"
    '';
  };
}
