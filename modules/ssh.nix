{lib, ...}: {
  environment.etc."ssh/sshd_config.d/nixos.conf".text = ''
    PermitRootLogin no
    X11Forwarding no
  '';
}
