{ ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
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
      SCARF_NO_ANALYTICS = "True";
      DO_NOT_TRACK = "True";
      ANONYMIZED_TELEMETRY = "False";
      HOME = ".";
    };
  };
}
