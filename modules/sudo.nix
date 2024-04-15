{ lib, ... }:
let
  securePaths = [
    "/run/system-manager/sw/bin"
    "/usr/local/sbin"
    "/usr/local/bin"
    "/usr/sbin"
    "/usr/bin"
  ];
in
{
  environment.etc."sudoers.d/nixos".text = ''
    Defaults secure_path="${lib.concatStringsSep ":" securePaths}"
  '';
}
