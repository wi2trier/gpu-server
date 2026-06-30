{
  lib',
  pkgs,
  ...
}:
{
  imports = lib'.flocken.getModules ./.;
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      git-lfs
      python3Packages.gpustat
      uv
      findgpu
      userctl
      build-apptainer
      build-container
      ollama
    ];
  };
}
