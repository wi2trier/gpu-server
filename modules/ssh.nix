{ lib, ... }:
let
  bannerFile = "sshd-banner.txt";
in
{
  environment.etc = {
    "ssh/sshd_config.d/nixos.conf".text = ''
      PermitRootLogin no
      X11Forwarding no
      Banner /etc/${bannerFile}
    '';
    ${bannerFile}.text = ''
      Welcome to our GPU server! Please check out the documentation.
      If you encounter any problems, feel free to open an issue on GitHub or contact your supervisor.

      https://github.com/wi2trier/gpu-server

    '';
  };
}
