{ ... }:
{
  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        image-base = pkgs.callPackage ../images/base.nix { };
        image-jupyter = pkgs.callPackage ../images/jupyter.nix { base = config.packages.image-base; };
        image-poetry = pkgs.callPackage ../images/poetry.nix { base = config.packages.image-base; };
      };
    };
}
