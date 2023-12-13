{lib, ...}: {
  environment.etc."ssh/ssh_config.d/nixos.conf".text = ''
    PermitRootLogin no;
    X11Forwarding no;
    Banner /etc/banner;
  '';
}
