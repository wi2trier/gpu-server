{ pkgs, lib, ... }:
let
  userctl = pkgs.writers.writePython3Bin "userctl" {
    libraries = with pkgs.python3Packages; [ typer ];
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } (builtins.readFile ./userctl.py);
in
{
  environment = {
    systemPackages = [ userctl ];
  };
}
