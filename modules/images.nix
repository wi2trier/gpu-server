{pkgs, ...}: {
  environment.etc = {
    "images/nlp.tar.gz" = pkgs.callPackage ../images/nlp.nix {};
    "images/poetry.tar.gz" = pkgs.callPackage ../images/poetry.nix {};
  };
}
