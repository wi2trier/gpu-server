{
  mylib,
  pkgs,
  inputs,
  ...
}: let
  nixglhost = inputs.nixglhost.defaultPackage.${pkgs.system};
in {
  imports = mylib.flocken.getModules ./.;
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      python3Packages.gpustat
      nixglhost
    ];
  };
}
