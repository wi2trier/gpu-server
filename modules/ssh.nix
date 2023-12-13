{lib, ...}: {
  environment.etc."ssh/ssh_config.d/nixos".text = ''
    PermitRootLogin no;
    X11Forwarding no;
    Banner /etc/banner;
  '';
}
