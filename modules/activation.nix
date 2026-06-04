{ pkgs, ... }:
let
  cudaSource = "/usr/lib/x86_64-linux-gnu";
  cudaTarget = "/run/opengl-driver/lib";
in
{
  systemd.services.gpu-server-activation = {
    description = "Apply GPU server host activation state";
    wantedBy = [ "multi-user.target" ];
    restartIfChanged = true;
    path = with pkgs; [
      coreutils
      findutils
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # refresh CDI devices for oci engines like podman
      /usr/bin/systemctl enable --now nvidia-cdi-refresh.path
      /usr/bin/systemctl restart nvidia-cdi-refresh.service

      # set compute mode (https://stackoverflow.com/a/50056586)
      # 0 Default
      # 1 Exclusive_Thread
      # 2 Prohibited
      # 3 Exclusive_Process
      /usr/bin/nvidia-smi -c 3

      # Keep Nix and Apptainer CUDA consumers pointed at the host driver libraries
      rm -rf ${cudaTarget}
      install -d -m 0755 ${cudaTarget}

      # Link all cuda .so files specified by Apptainer
      while IFS= read -r file; do
        case "$file" in
          *.so)
            for lib in ${cudaSource}/"$file".*; do
              [ -e "$lib" ] || continue
              ln -s "$lib" ${cudaTarget}/
            done
            ;;
        esac
      done < ${pkgs.apptainer}/etc/apptainer/nvliblist.conf

      # Remove broken cuda links
      find -L ${cudaTarget} -maxdepth 1 -type l -delete

      if [ -d /etc/update-motd.d ]; then
        for file in /etc/update-motd.d/*; do
          [ -e "$file" ] || continue
          chmod -x "$file"
        done
      fi
    '';
  };
}
