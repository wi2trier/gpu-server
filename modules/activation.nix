{ pkgs, ... }:
let
  cudaTarget = "/run/opengl-driver/lib";
in
{
  systemd.services.gpu-server-activation = {
    description = "Apply GPU server host activation state";
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = true;
    path = with pkgs; [ coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # generate the CDI spec for oci engines like podman
      install -d -m 0755 /etc/cdi
      /usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
      chmod -R 755 /etc/cdi

      # set compute mode (https://stackoverflow.com/a/50056586)
      # 0 Default
      # 1 Exclusive_Thread
      # 2 Prohibited
      # 3 Exclusive_Process
      /usr/bin/nvidia-smi -c 3

      # Expose the host NVIDIA driver libraries at /run/opengl-driver/lib, the
      # path nixpkgs' patched glibc searches by default, so Nix-built GPU tools
      # resolve the driver without a wrapper like nixGL (gpustat finds
      # libnvidia-ml, CUDA programs find libcuda). The library list is queried
      # from the running driver via the container toolkit, so it never goes
      # stale; ldconfig then recreates the versioned soname symlinks.
      rm -rf ${cudaTarget}.new
      install -d -m 0755 ${cudaTarget}.new
      /usr/bin/nvidia-container-cli list --libraries | while IFS= read -r lib; do
        [ -e "$lib" ] && ln -s "$lib" ${cudaTarget}.new/
      done
      /usr/sbin/ldconfig -n ${cudaTarget}.new
      # Only swap in the new directory if libraries were found, so a transient
      # query failure never wipes a working setup.
      if [ -n "$(ls -A ${cudaTarget}.new)" ]; then
        rm -rf ${cudaTarget} && mv ${cudaTarget}.new ${cudaTarget}
      else
        rm -rf ${cudaTarget}.new
      fi

      if [ -d /etc/update-motd.d ]; then
        for file in /etc/update-motd.d/*; do
          [ -e "$file" ] || continue
          chmod -x "$file"
        done
      fi
    '';
  };
}
