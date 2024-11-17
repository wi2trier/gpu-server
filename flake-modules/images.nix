{ ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        image-base = pkgs.callPackage ../images/base.nix { name = "base"; };
        image-jupyter = pkgs.callPackage ../images/jupyter.nix { base = config.packages.image-base; };
        image-poetry = pkgs.callPackage ../images/poetry.nix { base = config.packages.image-base; };
        image-uv = pkgs.callPackage ../images/uv.nix { base = config.packages.image-base; };
      };
    };
}
