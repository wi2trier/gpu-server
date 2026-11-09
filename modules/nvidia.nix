{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.gpu-server.gpus;
  count = 8;
  driverLibs = "${pkgs.addDriverRunpath.driverLink}/lib";
  # The NVIDIA driver registers its GPU and control devices under major 195.
  node = minor: mode: group: {
    c = {
      inherit mode group;
      argument = "195:${toString minor}";
    };
  };
  gpuNode =
    index:
    let
      reserved = lib.elem index cfg.reserved;
    in
    lib.nameValuePair "/dev/nvidia${toString index}" (
      node index (if reserved then "0660" else "0666") (if reserved then cfg.group else "root")
    );
in
{
  users.groups.${cfg.group} = { };

  # nvidia-modprobe, which libcuda invokes setuid root, resets every device node
  # to the driver defaults, so leave the nodes to systemd-tmpfiles instead.
  environment.etc."modprobe.d/gpu-server.conf".text = ''
    options nvidia NVreg_ModifyDeviceFiles=0
  '';

  systemd.tmpfiles.settings.gpu-server = {
    "/dev/nvidiactl" = node 255 "0666" "root";
  }
  // lib.listToAttrs (lib.genList gpuNode count);

  # Mirrors hardware.nvidia.nvidiaPersistenced of NixOS, which runs it as root.
  # Replaces NVIDIA's sample unit, whose --user privilege drop would lose
  # access to the reserved GPUs.
  systemd.services.nvidia-persistenced = {
    description = "NVIDIA Persistence Daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      Restart = "always";
      RuntimeDirectory = "nvidia-persistenced";
      PIDFile = "/run/nvidia-persistenced/nvidia-persistenced.pid";
      ExecStart = "/usr/bin/nvidia-persistenced --verbose";
    };
  };

  # Comments stay outside the script, since any change to it restarts the
  # llama.cpp workers through their Requires=.
  # 1. Load nvidia-uvm and create its nodes, which keep the driver defaults
  #    since its major number is dynamic.
  # 2. Set the compute mode, which has no driver or config file setting.
  # 3. Expose the host driver libraries at the path nixpkgs' glibc searches,
  #    so Nix-built tools find libcuda and libnvidia-ml without nixGL.
  #    The list comes from the running driver and is only swapped in when
  #    non-empty, so a transient query failure keeps the working setup.
  systemd.services.gpu-server-nvidia = {
    description = "Prepare the NVIDIA GPUs";
    wantedBy = [ "multi-user.target" ];
    # Persistence keeps the GPUs and their compute mode initialized.
    after = [ "nvidia-persistenced.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      /usr/bin/nvidia-modprobe --unified-memory --create-nvidia-device-file=0

      /usr/bin/nvidia-smi --compute-mode=EXCLUSIVE_PROCESS

      rm -rf ${driverLibs}.new
      install -d -m 0755 ${driverLibs}.new
      /usr/bin/nvidia-container-cli list --libraries | while IFS= read -r lib; do
        [ -e "$lib" ] && ln -s "$lib" ${driverLibs}.new/
      done
      /usr/sbin/ldconfig -n ${driverLibs}.new

      if [ -n "$(ls -A ${driverLibs}.new)" ]; then
        rm -rf ${driverLibs} && mv ${driverLibs}.new ${driverLibs}
      else
        rm -rf ${driverLibs}.new
      fi
    '';
  };
}
