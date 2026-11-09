{ inputs }:
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
  system-manager = inputs.system-manager.packages.${system}.default;
  imageBase = final.callPackage ./image-base.nix { };
  inherit exports;

  # CUDA 13 dropped support for the V100 cards.
  cudaPackages = prev.cudaPackages_12_9;
  # posthog is broken since mcp 2, and its timing-based tests are flaky under load.
  # Remove once https://github.com/NixOS/nixpkgs/pull/578265 lands.
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (pyFinal: pyPrev: {
      posthog = pyPrev.posthog.overridePythonAttrs (old: {
        doCheck = false;
        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];
  # NCCL provides fast multi-GPU AllReduce for tensor-split models. Nixpkgs has
  # no flag for it, so enable GGML_CUDA_NCCL and add the library by hand.
  llama-cpp = (prev.llama-cpp.override { cudaSupport = true; }).overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ final.cudaPackages.nccl ];
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      (lib.cmakeBool "GGML_CUDA_NCCL" true)
    ];
  });
}
// exports
