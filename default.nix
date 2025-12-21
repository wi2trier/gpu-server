# https://github.com/Mic92/nix-update/blob/main/nix_update/eval.py#L142
{
  system ? builtins.currentSystem,
  ...
}:
let
  flake = builtins.getFlake ("git+file://" + toString ./.);
  overlay = import ./overlays {
    inherit (flake) inputs nixpkgsConfig;
  };
in
import flake.inputs.nixpkgs {
  inherit system;
  overlays = [ overlay ];
  config = flake.nixpkgsConfig;
}
