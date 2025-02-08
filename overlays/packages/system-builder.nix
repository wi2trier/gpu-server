{
  lib,
  system-manager,
  system-setup,
  writeShellApplication,
  selfOutPath,
}:
writeShellApplication {
  name = "system-builder";
  text = ''
    set -x #echo on
    ${lib.getExe' system-manager "system-manager"} "''${1:-switch}" --flake ${selfOutPath} "''${@:2}"
    ${lib.getExe system-setup}
  '';
}
