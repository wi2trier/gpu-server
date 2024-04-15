{ lib, pkgs, ... }:
{
  systemd.services = {
    update-system = {
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
          ${lib.getExe' pkgs.coreutils "rm"} -rf ${target}
          ${lib.getExe' pkgs.coreutils "mkdir"} -p ${target}
          # Link all .so files specified in Apptainer
          ${lib.getExe pkgs.gnugrep} '\.so$' ${pkgs.apptainer}/etc/apptainer/nvliblist.conf | while read file
          do
            ${lib.getExe' pkgs.coreutils "ln"} -s ${source}/$file.* ${target}
          done
          # Remove broken links
          ${lib.getExe pkgs.findutils} -L ${target} -maxdepth 1 -type l -delete
        '';
      };
  };
}
