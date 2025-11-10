{ ... }:
{
  nix = {
    enable = true;
    settings = {
      always-allow-substitutes = true;
      auto-optimise-store = true;
      build-users-group = "nixbld";
      builders-use-substitutes = true;
      experimental-features = [
        "flakes"
        "nix-command"
        "no-url-literals"
        "pipe-operators"
      ];
      extra-nix-path = "nixpkgs=flake:nixpkgs";
      keep-derivations = false;
      keep-failed = false;
      keep-going = true;
      keep-outputs = true;
      log-lines = 1000;
      max-jobs = "auto";
      sandbox = true;
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "wi2trier.cachix.org-1:8wJvKtRD8XUqYZMdjECTsN1zWxHy9kvp5aoPQiAm1fY="
        "recap.cachix.org-1:KElwRDtaJbbQxmmS2SyxWHqs9bdJbaZHzb2iINTfQws="
        "pyproject-nix.cachix.org-1:UNzugsOlQIu2iOz0VyZNBQm2JSrL/kwxeCcFGw+jMe0= mirkolenz.cachix.org-1:R0dgCJ93t33K/gncNbKgUdJzwgsYVXeExRsZNz5jpho="
        "mirkolenz.cachix.org-1:R0dgCJ93t33K/gncNbKgUdJzwgsYVXeExRsZNz5jpho="
        "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
      ];
      trusted-substituters = [
        "https://nix-community.cachix.org"
        "https://wi2trier.cachix.org"
        "https://recap.cachix.org"
        "https://pyproject-nix.cachix.org"
        "https://mirkolenz.cachix.org"
        "https://install.determinate.systems"
      ];
      warn-dirty = false;
    };
    extraOptions = ''
      !include nix.custom.conf
    '';
  };
}
