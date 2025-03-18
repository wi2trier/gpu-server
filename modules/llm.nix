{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.ollama-bin;
    acceleration = "cuda";
    # https://github.com/ollama/ollama/blob/main/docs/faq.md
    # ollama serve --help
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "16384";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KEEP_ALIVE = "10m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_MAX_LOADED_MODELS = "4";
      OLLAMA_MAX_QUEUE = "64";
      OLLAMA_NUM_PARALLEL = "1";
    };
    loadModels = [
      "aya-expanse:32b"
      "command-r:35b"
      "deepseek-r1:32b"
      "gemma2:27b"
      "mistral-small:24b"
      "phi4:14b"
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
