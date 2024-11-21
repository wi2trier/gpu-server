{ lib, pkgs, ... }:
{
  systemd = {
    enableStrictShellChecks = true;
    services = {
      update-system = {
        enable = true;
        startAt = "*-*-* 04:00:00";
        script = ''
          ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server
          ${lib.getExe pkgs.nix} run github:wi2trier/gpu-server#setup
        '';
        serviceConfig.Type = "oneshot";
      };
      link-cuda =
        let
          source = "/usr/lib/x86_64-linux-gnu";
          target = "/run/opengl-driver/lib";
        in
        {
          enable = true;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          wantedBy = [ "system-manager.target" ];
          script = ''
            # Remove old links
            rm -rf ${target}
            mkdir -p ${target}

            # Link all .so files specified in Apptainer
            grep '\.so$' ${pkgs.apptainer}/etc/apptainer/nvliblist.conf | while read file; do
              ln -s ${source}/$file.* ${target}
            done

            # Remove broken links
            find -L ${target} -maxdepth 1 -type l -delete
          '';
        };
    };
  };
}
