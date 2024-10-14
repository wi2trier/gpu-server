{ lib', pkgs, ... }:
{
  imports = lib'.flocken.getModules ./.;
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      python3Packages.gpustat
      nixglhost
      uv
    ];
  };
}
