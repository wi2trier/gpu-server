# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sourced by fish built with nix
{ ... }:
let
  # 100 is a non-existent device id, so by default no process grabs every GPU.
  # Container wrappers and findgpu translate it into a concrete free GPU.
  noGpu = "100";
  # Without a fixed order, nvidia-smi indices disagree with CUDA_VISIBLE_DEVICES.
  deviceOrder = "PCI_BUS_ID";
in
{
  environment.etc = {
    "profile.d/posix-config.sh".text = ''
      export CUDA_VISIBLE_DEVICES="${noGpu}"
      export CUDA_DEVICE_ORDER="${deviceOrder}"
    '';
    "fish/config.fish".text = ''
      fish_add_path "/run/system-manager/sw/bin"
      set -gx CUDA_VISIBLE_DEVICES "${noGpu}"
      set -gx CUDA_DEVICE_ORDER "${deviceOrder}"
    '';
  };
}
