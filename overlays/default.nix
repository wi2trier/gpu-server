{
  inputs,
  nixpkgsConfig,
}:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;
  inherit (prev) lib;
  exports = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith (
      final
      // {
        inherit inputs;
      }
    );
    directory = ./packages;
  };
in
{
  unstable = prev;
  stable = import inputs.nixpkgs-stable {
    inherit system;
    config = nixpkgsConfig;
  };
  system-manager = inputs.system-manager.packages.${system}.default;
  imageBase = final.callPackage ./image-base.nix { };
  inherit exports;
}
// exports
