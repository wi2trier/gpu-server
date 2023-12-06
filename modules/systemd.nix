{
  lib,
  pkgs,
  ...
}: {
  systemd.timers = {
    update-system = {
      enable = true;
      timerConfig = {
        OnCalendar = "*-*-* 04:00:00";
        Persistent = true;
        Unit = "update-system.service";
      };
      wantedBy = ["system-manager.target"];
    };
  };
  systemd.services = {
    update-system = {
      enable = true;
      script = ''
        ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server
      '';
      serviceConfig = {
        Type = "oneshot";
      };
    };
    link-cuda = let
      # Regenerate with: nvidia-container-cli list --libraries
      libraries = [
        "libnvidia-ml.so"
        "libnvidia-cfg.so"
        "libcuda.so"
        "libcudadebugger.so"
        "libnvidia-opencl.so"
        "libnvidia-gpucomp.so"
        "libnvidia-ptxjitcompiler.so"
        "libnvidia-allocator.so"
        "libnvidia-pkcs11.so"
        "libnvidia-pkcs11-openssl3.so"
        "libnvidia-nvvm.so"
        "libnvidia-ngx.so"
        "libnvidia-encode.so"
        "libnvidia-opticalflow.so"
        "libnvcuvid.so"
        "libnvidia-eglcore.so"
        "libnvidia-glcore.so"
        "libnvidia-tls.so"
        "libnvidia-glsi.so"
        "libnvidia-fbc.so"
        "libnvidia-rtcore.so"
        "libnvoptix.so"
        "libGLX_nvidia.so"
        "libEGL_nvidia.so"
        "libGLESv2_nvidia.so"
        "libGLESv1_CM_nvidia.so"
        "libnvidia-glvkspirv.so"
      ];
    in {
      enable = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = ["system-manager.target"];
      script = ''
        mkdir -p /run/opengl-driver/lib
        rm -rf /run/opengl-driver/lib/*
        # ln -s /usr/lib/x86_64-linux-gnu/lib*{cuda,nvidia}*.so.* /run/opengl-driver/lib
        ${lib.concatLines (builtins.map (entry: "ln -s /usr/lib/x86_64-linux-gnu/${entry}.* /run/opengl-driver/lib") libraries)}
      '';
    };
  };
}
