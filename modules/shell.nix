# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
# We use config.fish directly since conf.d is not sourced by fish built with nix
{ lib, ... }:
let
  # Not environment.sessionVariables, since profile.d and the fish config
  # re-export those in every new shell, clobbering an explicit user choice.
  # pam_env covers every session including SSH commands, VS Code Remote and cron,
  # and environment.d covers systemd user services.
  defaultVariables = {
    # CUDA stops at the first invalid id, so by default no process grabs every GPU.
    # findgpu and the binaries wrapped by it replace it with a free GPU.
    CUDA_VISIBLE_DEVICES = "-1";
    # Without a fixed order, nvidia-smi indices disagree with CUDA_VISIBLE_DEVICES.
    CUDA_DEVICE_ORDER = "PCI_BUS_ID";
  };
in
{
  environment.etc = {
    "security/pam_env.conf" = {
      replaceExisting = true;
      text = lib.concatLines (lib.mapAttrsToList (k: v: "${k} DEFAULT=${v}") defaultVariables);
    };
    "environment.d/50-gpu-server.conf".text = lib.toShellVars defaultVariables;
    "fish/config.fish".text = ''
      fish_add_path --path "/run/system-manager/sw/bin"
    '';
  };
}
