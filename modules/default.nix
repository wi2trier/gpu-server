{
  lib',
  pkgs,
  inputs,
  ...
}:
{
  imports = (lib'.flocken.getModules ./.) ++ [
    inputs.quadlet-nix.nixosModules.default
  ];
  environment = {
    systemPackages = with pkgs; [
      nix
      git
      python3Packages.gpustat
      nixglhost
      uv
      findgpu
      userctl
      build-apptainer
      build-container
    ];
  };
}
