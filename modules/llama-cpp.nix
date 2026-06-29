{
  inputs,
  pkgs,
  ...
}:
{
  # `core` carries the llmhop reverse proxy plus the llama.cpp systemd backend.
  # The quadlet backends (vllm, sglang) are deliberately left out since
  # system-manager cannot run quadlet units.
  imports = [ inputs.llmhop.nixosModules.core ];

  services.llmhop = {
    enable = true;
    settings.listen = "127.0.0.1:18000";

    llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp.override { cudaSupport = true; };
      # Keep nvidia-smi indices in sync with CUDA_VISIBLE_DEVICES.
      environment.CUDA_DEVICE_ORDER = "PCI_BUS_ID";

      # https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md
      # Shared across both workers. Each model gets a full Tesla V100 (32 GB) to
      # itself, so the per-model budget matches a single-card deployment.
      modelSettings = rec {
        # keep-sorted start
        cache-ram = 128 * 1024; # MiB
        cache-type-k = "q8_0";
        cache-type-v = "q8_0";
        ctx-size = 96 * 1024 * parallel;
        flash-attn = "on";
        mlock = true;
        mmap = false;
        n-gpu-layers = "all";
        parallel = 2;
        # keep-sorted end
      };

      # The cards run in exclusive process mode, so each always-on model is
      # pinned to a distinct GPU within the GPUs 0-3 NVLink node.
      models = {
        # https://unsloth.ai/docs/models/qwen3.6
        # Reasoning model with multi-token-prediction speculative decoding.
        "qwen3.6-27b" = {
          enable = true;
          port = 18101;
          environment.CUDA_VISIBLE_DEVICES = "0";
          settings = {
            # keep-sorted start
            hf-repo = "unsloth/Qwen3.6-27B-MTP-GGUF:UD-Q4_K_XL";
            min-p = 0.00;
            reasoning = "on";
            spec-draft-n-max = 4;
            spec-type = "draft-mtp";
            temperature = 1.0;
            top-k = 20;
            top-p = 0.95;
            # keep-sorted end
          };
        };
        # https://unsloth.ai/docs/models/gemma-4/qat
        # Non-reasoning dense model without an MTP draft, so no speculation.
        "gemma4-31b" = {
          enable = true;
          port = 18102;
          environment.CUDA_VISIBLE_DEVICES = "1";
          settings = {
            # keep-sorted start
            hf-repo = "unsloth/gemma-4-31B-it-qat-GGUF:UD-Q4_K_XL";
            reasoning = "off";
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
