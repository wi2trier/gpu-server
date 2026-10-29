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

  # CUDA-specific adjustments for the V100 cards. NCCL dlopens libnvidia-ml.so.1
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
  # open-webui still imports the mcp 1 client API that was removed in mcp 2.
  # Remove once https://github.com/NixOS/nixpkgs/pull/580342 reaches nixos-unstable.
  open-webui = prev.open-webui.override {
    python3Packages = final.python3Packages.overrideScope (pyFinal: pyPrev: { mcp = pyFinal.mcp_1; });
  };
  # NCCL provides fast multi-GPU AllReduce for tensor-split models. Nixpkgs has
  # no flag for it, so enable GGML_CUDA_NCCL and add the library by hand.
  # CUDA graphs leak VRAM with speculative decoding and can fail on Volta.
  # https://github.com/ggml-org/llama.cpp/issues/25835
  llama-cpp = (prev.llama-cpp.override { cudaSupport = true; }).overrideAttrs (old: {
    buildInputs = (old.buildInputs or [ ]) ++ [ final.cudaPackages.nccl ];
    cmakeFlags = (old.cmakeFlags or [ ]) ++ [
      (lib.cmakeBool "GGML_CUDA_GRAPHS" false)
      (lib.cmakeBool "GGML_CUDA_NCCL" true)
    ];
  });
}
// exports
