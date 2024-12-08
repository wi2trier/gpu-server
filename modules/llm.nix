{ ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "4,5,6,7";
    };
  };
  services.open-webui = {
    enable = true;
    host = "0.0.0.0";
    port = 8000;
  };
}
