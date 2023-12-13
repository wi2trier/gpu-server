{pkgs, ...}: {
  environment.etc = {
    "images/nlp.tar.gz".source = pkgs.callPackage ../images/nlp.nix {};
    "images/poetry.tar.gz".source = pkgs.callPackage ../images/poetry.nix {};
  };
}
