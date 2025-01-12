{
  inputs,
  nixpkgsConfig,
}:
final: prev:
let
  inherit (final.stdenv.hostPlatform) system;
in
{
  stable = prev;
  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config = nixpkgsConfig;
  };
  inherit (final.unstable) uv open-webui ollama;
  apptainer = prev.apptainer.override {
    enableNvidiaContainerCli = false;
    forceNvcCli = false;
  };
  system-manager = inputs.system-manager.packages.${system}.default;
  nixglhost = inputs.nixglhost.packages.${system}.default;
  system-setup = final.callPackage ./system-setup.nix { };
  mkCudaWrapper = final.callPackage ./cuda-wrapper.nix { };
  findgpu = final.writers.writePython3Bin "findgpu" {
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } (builtins.readFile ./findgpu.py);
  userctl = final.writers.writePython3Bin "userctl" {
    libraries = with final.python3Packages; [ typer ];
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } (builtins.readFile ./userctl.py);
  build-container = final.callPackage ./build-container.nix { inherit (inputs) self; };
  build-apptainer = final.callPackage ./build-apptainer.nix { };
  ollama-bin = final.callPackage ./ollama.nix { };
}
