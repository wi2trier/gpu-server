{ ... }:
{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    environmentVariables = {
      CUDA_VISIBLE_DEVICES = "4,5,6,7";
    };
  };
}
