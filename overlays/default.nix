{
  inputs,
  nixpkgsConfig,
}:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;
  inherit (prev) lib;
  exports = lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ./packages;
  };
in
{
  stable = prev;
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = nixpkgsConfig;
  };
  inherit (final.unstable) uv open-webui ollama;
  system-manager = inputs.system-manager.packages.${system}.default;
  nixglhost = inputs.nixglhost.packages.${system}.default;
  mkCudaWrapper = final.callPackage ./cuda-wrapper.nix { };
  imageBase = final.callPackage ./image-base.nix { };
  selfOutPath = inputs.self.outPath;
  inherit exports;
}
// exports
