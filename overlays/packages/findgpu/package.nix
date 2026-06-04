{ writers }:
writers.writePython3Bin "findgpu" {
  flakeIgnore = [
    "E203"
    "E501"
  ];
} ./script.py
