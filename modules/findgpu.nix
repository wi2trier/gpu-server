{pkgs, ...}: let
  app =
    pkgs.writers.writePython3Bin "findgpu" {
      libraries = with pkgs.python3Packages; [];
      flakeIgnore = ["E203" "E501"];
    }
    (builtins.readFile ./findgpu.py);
in {
  environment = {
    systemPackages = [app];
    etc = {
      # Make sure that no user uses all GPUs accidentally
      "profile.d/gpu-selection.sh".text = ''
        export CUDA_VISIBLE_DEVICES="100"
      '';
    };
  };
}
