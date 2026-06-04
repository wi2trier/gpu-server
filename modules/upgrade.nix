{ ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:wi2trier/gpu-server";
  };
}
