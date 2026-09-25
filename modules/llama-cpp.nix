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
          port = 18101;
          environment = {
            CUDA_VISIBLE_DEVICES = "0,1,2,3";
            GGML_CUDA_P2P = "1";
          };
          settings = {
            # keep-sorted start
            hf-repo = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
            min-p = 0.0;
            spec-draft-n-max = 2;
            spec-draft-ngl = "all";
            spec-type = "draft-mtp";
            # Tensor splitting has a reported V100 hang with this model.
            # https://github.com/ggml-org/llama.cpp/issues/27366
            split-mode = "layer";
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
