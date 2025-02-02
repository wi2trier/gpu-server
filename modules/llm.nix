{ ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    # https://github.com/ollama/ollama/blob/main/docs/faq.md
    # ollama serve --help
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KEEP_ALIVE = "1m";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_MAX_LOADED_MODELS = "2";
      OLLAMA_MAX_QUEUE = "64";
      OLLAMA_NUM_PARALLEL = "1";
    };
    loadModels = [
      "aya-expanse:32b"
      "aya-expanse:8b"
      "command-r:35b"
      "command-r7b:7b"
      "deepseek-r1:14b"
      "deepseek-r1:70b"
      "gemma2:27b"
      "gemma2:9b"
      "llama3.2:3b"
      "llama3.3:70b"
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
