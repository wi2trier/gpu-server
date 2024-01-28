# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sources by fish built with nix
{pkgs, ...}: {
  environment.etc."fish/config.fish".source = pkgs.writeTextFile {
    name = "config.fish";
    executable = true;
    text = ''
      set -gx PATH "/run/system-manager/sw/bin" $PATH
      set -gx CUDA_VISIBLE_DEVICES 100
      set -gx CUDA_DEVICE_ORDER PCI_BUS_ID
    '';
  };
}
