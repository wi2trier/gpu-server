{
  inputs,
  system,
  config,
}:
final: prev: {
  stable = prev;
  unstable = import inputs.nixpkgs-unstable {
    inherit system config;
  };
  apptainer = prev.apptainer.override {
    enableNvidiaContainerCli = false;
    forceNvcCli = false;
  };
  system-manager = inputs.system-manager.packages.${system}.default;
  nixglhost = inputs.nixglhost.packages.${system}.default;
  inherit (final.unstable) uv open-webui;
  ollama = final.unstable.ollama.override {
    acceleration = "cuda";
  };
  system-setup = final.callPackage ./system-setup.nix { };
  mkCudaWrapper = final.callPackage ./cuda-wrapper.nix { };
}
