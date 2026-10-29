# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sourced by fish built with nix
{ config, lib, ... }:
{
  environment.sessionVariables = {
    # 100 is a non-existent device id, so by default no process grabs every GPU.
    # Container wrappers and findgpu translate it into a concrete free GPU.
    CUDA_VISIBLE_DEVICES = "100";
    # Without a fixed order, nvidia-smi indices disagree with CUDA_VISIBLE_DEVICES.
    CUDA_DEVICE_ORDER = "PCI_BUS_ID";
  };
  # system-manager only exports variables for POSIX shells, mirror them for fish.
  environment.etc."fish/config.fish".text = ''
    fish_add_path --path "/run/system-manager/sw/bin"
    ${lib.concatLines (lib.mapAttrsToList (k: v: ''set -gx ${k} "${v}"'') config.environment.variables)}
  '';
}
