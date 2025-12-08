{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    # package = pkgs.ollama;
    package = pkgs.ollama-bin;
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
      "gemma3:27b"
      "gpt-oss:20b"
      "mistral-small3.2:24b"
      "qwen3:32b"
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
