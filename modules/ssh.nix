{lib, ...}: {
  environment.etc."ssh/sshd_config.d/nixos.conf".text = ''
    PermitRootLogin no
    X11Forwarding no
    Banner /etc/sshd_banner.txt
    PrintMotd no
  '';
  environment.etc."sshd_banner.txt".text = ''
    Welcome to our GPU server! Please check out the documentation:
    https://github.com/wi2trier/gpu-server

  '';
}
