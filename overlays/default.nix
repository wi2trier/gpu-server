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

  # cuda-specific adjustments for the v100 cards
  cudaPackages = prev.cudaPackages_12_9;
  ollama = prev.ollama.override { acceleration = "cuda"; };
  llama-cpp = prev.llama-cpp.override { cudaSupport = true; };
}
// exports
