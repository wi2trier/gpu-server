{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    system-manager = {
      url = "github:numtide/system-manager/073f275b566b83be3183375337ee96f05f8dda33";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixglhost = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flocken = {
      url = "github:mirkolenz/flocken/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake {
      inherit inputs;
      specialArgs = {
        lib' = {
          # self = self.lib;
          flocken = inputs.flocken.lib;
        };
      };
    } { imports = [ ./flake-modules ]; };
}
