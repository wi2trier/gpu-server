{
  lib',
  pkgs,
  inputs,
  ...
}: let
  nixglhost = inputs.nixglhost.defaultPackage.${pkgs.system};
in {
  imports = lib'.flocken.getModules ./.;
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      python3Packages.gpustat
      nixglhost
    ];
  };
}
