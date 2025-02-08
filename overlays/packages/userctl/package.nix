{ writers, python3Packages }:
writers.writePython3Bin "userctl" {
  libraries = with python3Packages; [ typer ];
  flakeIgnore = [
    "E203"
    "E501"
  ];
} ./script.py
