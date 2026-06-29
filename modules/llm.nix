{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (llama-cpp.override {
      cudaSupport = true;
    })
  ];
  services.ollama = {
    enable = true;
    package = pkgs.ollama.override {
      acceleration = "cuda";
      cudaArches = [ "sm_70" ];
    };
    # package = pkgs.ollama-bin;
    # https://github.com/ollama/ollama/blob/main/docs/faq.md
    # ollama serve --help
    environmentVariables = {
      CUDA_DEVICE_ORDER = "PCI_BUS_ID";
      CUDA_VISIBLE_DEVICES = "0,1";
      OLLAMA_CONTEXT_LENGTH = "16384";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KEEP_ALIVE = "10m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_MAX_LOADED_MODELS = "2";
      OLLAMA_MAX_QUEUE = "64";
      OLLAMA_NUM_PARALLEL = "1";
    };
    syncModels = true;
    loadModels = [
      "gemma4:31b"
      "qwen3.6:27b"
    ];
  };
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8000;
    environment = {
      ANONYMIZED_TELEMETRY = "False";
      BYPASS_MODEL_ACCESS_CONTROL = "True";
      DO_NOT_TRACK = "True";
      HOME = ".";
      SCARF_NO_ANALYTICS = "True";
    };
  };
}
