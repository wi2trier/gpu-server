{
  mylib,
  pkgs,
  lib,
  inputs,
  ...
}: let
  nixglhost = inputs.nixglhost.defaultPackage.${pkgs.system};
  # currently not working because system-mamanger does not allow impure nix builds
  nixgl = inputs.nixgl.packages.${pkgs.system}.nixGLNvidia;
  wrapgl = drv:
    pkgs.writeShellApplication {
      name = lib.getName drv;
      text = ''
        export LD_LIBRARY_PATH="/run/opengl-driver/lib:''${LD_LIBRARY_PATH:-}"
        exec ${lib.getExe drv} "$@"
      '';
    };
in {
  imports = mylib.importFolder ./.;
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      python3Packages.gpustat
      nixglhost
    ];
  };
}
