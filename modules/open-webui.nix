{ ... }:
{
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
      # Serve the llama.cpp models through the llmhop OpenAI-compatible gateway.
      ENABLE_OLLAMA_API = "False";
      ENABLE_OPENAI_API = "True";
      OPENAI_API_BASE_URL = "http://127.0.0.1:18000/v1";
      OPENAI_API_KEY = "sk-llmhop";
    };
  };
}
