{pkgs, ...}: let
  app =
    pkgs.writers.writePython3Bin "findgpu" {
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
        export CUDA_DEVICE_ORDER="PCI_BUS_ID
      '';
    };
  };
}
