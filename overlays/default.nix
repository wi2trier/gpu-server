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

  # cuda-specific adjustments for the v100 cards. NCCL dlopens libnvidia-ml.so.1
  # at runtime for NVLink topology, but that is a driver library (like libcuda)
  # and the nixpkgs nccl lacks the driver runpath, so bake it in globally via
  # autoAddDriverRunpath, letting every consumer resolve /run/opengl-driver/lib.
  cudaPackages = prev.cudaPackages_12_9.overrideScope (
    cudaFinal: cudaPrev: {
      nccl = cudaPrev.nccl.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.autoAddDriverRunpath ];
      });
    }
  );
  ollama = prev.ollama.override { acceleration = "cuda"; };
  # NCCL provides fast multi-GPU AllReduce for tensor-split models; nixpkgs has
  # no flag for it, so enable GGML_CUDA_NCCL and add the library by hand.
  llama-cpp = (prev.llama-cpp.override { cudaSupport = true; }).overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ final.cudaPackages.nccl ];
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      (lib.cmakeBool "GGML_CUDA_NCCL" true)
    ];
  });
}
// exports
