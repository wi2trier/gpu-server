{pkgs, ...}: let
  json = pkgs.formats.json {};
in {
  environment.etc."nix/registry.json".source = json.generate "registry.json" {
    version = 2;
    flakes = [
      {
        from = {
          type = "indirect";
          id = "nixpkgs";
        };
        to = {
          type = "path";
          path = pkgs.path;
        };
      }
    ];
  };
}
