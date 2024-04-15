{ pkgs, ... }:
let
  app = pkgs.writers.writePython3Bin "findgpu" {
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } (builtins.readFile ./findgpu.py);
in
{
  environment = {
    systemPackages = [ app ];
  };
}
