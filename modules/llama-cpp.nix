{
  config,
  lib,
  pkgs,
  ...
}:
let
  models = lib.attrValues (
    lib.filterAttrs (_: model: model.enable) config.services.llmhop.llama-cpp.models
  );
  dependencies = [ "gpu-server-nvidia.service" ];
  gpus = lib.range 0 3;
in
{
  environment.systemPackages = lib.singleton (pkgs.findgpu.wrap pkgs.llama-cpp);

  gpu-server.gpus.reserved = gpus;

  systemd.services = lib.genAttrs' models (
    model:
    lib.nameValuePair model.unit {
      # Without the driver libraries, ggml silently falls back to the CPU,
      # and DeviceAllow only resolves the uvm major once its module is loaded.
      after = dependencies;
      requires = dependencies;
      serviceConfig.SupplementaryGroups = [ config.gpu-server.gpus.group ];
    }
  );

  services.llmhop = {
    gateway = {
      type = "llmhop";
      llmhop.listen.default.port = 18000;
    };

    llama-cpp = {
      enable = true;

      # Qwen3.8 has a native 256 KiB context. llama-server divides ctx-size
      # across its slots, so reserve one full context for each request.
      modelSettings = rec {
        # keep-sorted start
        cache-ram = 0;
        cache-type-k = "f16";
        cache-type-v = "f16";
        ctx-size = 256 * 1024 * parallel;
        fit = "off";
        flash-attn = "on";
        kv-unified = false;
        load-mode = "mlock";
        n-gpu-layers = "all";
        parallel = 4;
        reasoning-preserve = true;
        # keep-sorted end
      };

      models = {
        # https://huggingface.co/Qwen/Qwen3.8-27B
        "qwen3.8-27b" = {
          model = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
          # The group may open every reserved GPU, so confine the model to its own.
          # CUDA then numbers them from 0 in the unit.
          native.devices = [
            "/dev/nvidiactl"
            "char-nvidia-uvm"
          ]
          ++ map (index: "/dev/nvidia${toString index}") gpus;
          environment = {
            # CUDA graphs leak VRAM with speculative decoding on Volta.
            # Any value disables them, so remove the variable to enable them.
            # https://github.com/ggml-org/llama.cpp/issues/25835
            # GGML_CUDA_DISABLE_GRAPHS = "1";
            GGML_CUDA_P2P = "1";
          };
          settings = {
            # keep-sorted start
            min-p = 0.0;
            spec-draft-n-max = 2;
            spec-draft-ngl = "all";
            spec-type = "draft-mtp";
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
