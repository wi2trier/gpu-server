{ writeShellApplication, apptainer }:
let
  cudaSource = "/usr/lib/x86_64-linux-gnu";
  cudaTarget = "/run/opengl-driver/lib";
in
writeShellApplication {
  name = "system-setup";
  text = ''
    # set up nix configuration
    cp -f ${../../etc/nix.conf} /etc/nix/nix.conf

    # set up cuda support for oci engines like podman
    /usr/bin/nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
    chmod -R 755 /etc/cdi

    # set compute mode (https://stackoverflow.com/a/50056586)
    # 0 Default
    # 1 Exclusive_Thread
    # 2 Prohibited
    # 3 Exclusive_Process
    /usr/bin/nvidia-smi -c 3

    # disable default motd
    chmod -x /etc/update-motd.d/*

    # Remove old cuda links
    rm -rf ${cudaTarget}
    mkdir -p ${cudaTarget}

    # Link all cuda .so files specified in Apptainer
    grep '\.so$' ${apptainer}/etc/apptainer/nvliblist.conf | while read -r file; do
      ln -s ${cudaSource}/"$file".* ${cudaTarget}
    done

    # Remove broken cuda links
    find -L ${cudaTarget} -maxdepth 1 -type l -delete
  '';
}
