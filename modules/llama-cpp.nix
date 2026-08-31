{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # The default module carries the llmhop reverse proxy and native backends.
  # The quadlet backends are deliberately left out since
  # system-manager cannot run quadlet units.
  imports = [ inputs.llmhop.nixosModules.default ];

  environment.systemPackages = with pkgs; [
    llama-cpp
  ];

  # llmhop only orders the workers after network.target, so they race the
  # activation service that populates /run/opengl-driver/lib. Losing that race
  # is silent: ggml dlopens its CUDA backend, the missing libcuda.so.1 makes the
  # load fail, and the suppressed error leaves the worker serving from CPU.
  systemd.services = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "llama-cpp-${name}" {
      after = [ "gpu-server-activation.service" ];
      requires = [ "gpu-server-activation.service" ];
    }
  ) (lib.filterAttrs (_: model: model.enable) config.services.llmhop.llama-cpp.models);

  services.llmhop = {
    enable = true;
    host = "127.0.0.1";
    port = 18000;

    llama-cpp = {
      enable = true;
      # Keep nvidia-smi indices in sync with CUDA_VISIBLE_DEVICES.
      environment.CUDA_DEVICE_ORDER = "PCI_BUS_ID";

      # https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
      # Shared across both workers. Each model gets a full Tesla V100 (32 GB) to
      # itself, so the per-model budget matches a single-card deployment.
      modelSettings = rec {
        # keep-sorted start
        cache-ram = 64 * 1024; # MiB
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        ctx-size = 128 * 1024 * parallel;
        fit = "off";
        flash-attn = "auto";
        kv-unified = false;
        load-mode = "mlock";
        n-gpu-layers = "all";
        parallel = 1;
        reasoning-preserve = true;
        # keep-sorted end
      };

      # The cards run in exclusive process mode. Single-GPU models are pinned to
      # a distinct card within the GPUs 0-3 NVLink node, while larger models are
      # sharded across the GPUs 4-7 NVLink node.
      models = {
        # https://unsloth.ai/docs/models/qwen3.6
        "qwen3.8-27b" = {
          port = 18101;
          environment.CUDA_VISIBLE_DEVICES = "0";
          settings = {
            # keep-sorted start
            hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
            min-p = 0.0;
            temperature = 1.0;
            top-k = 20;
            top-p = 0.95;
            # keep-sorted end
          };
        };
        # https://unsloth.ai/docs/models/gemma-4/qat
        "gemma4-31b" = {
          port = 18102;
          environment.CUDA_VISIBLE_DEVICES = "1";
          settings = {
            # keep-sorted start
            hf-repo = "unsloth/gemma-4-31B-it-qat-GGUF:UD-Q4_K_XL";
            temperature = 1.0;
            top-k = 20;
            top-p = 0.95;
            # keep-sorted end
          };
        };
        # https://unsloth.ai/docs/models/qwen3.5
        "qwen3.5-122b-a10b" = {
          enable = false;
          port = 18103;
          # NVLink P2P lets the four cards copy directly over NVLink instead of
          # bouncing through host memory; validate output and unset if unstable.
          environment = {
            CUDA_VISIBLE_DEVICES = "4,5,6,7";
            GGML_CUDA_P2P = "1";
            NCCL_DEBUG = "WARN";
          };
          settings = {
            # keep-sorted start
            fit = "off"; # incompatible with tensor split
            hf-repo = "unsloth/Qwen3.5-122B-A10B-MTP-GGUF:UD-Q4_K_XL";
            image-min-tokens = 1024;
            min-p = 0.0;
            split-mode = "tensor";
            temperature = 1.0;
            top-k = 20;
            top-p = 0.95;
            # keep-sorted end
          };
        };
      };
    };
  };
}
