{
  lib',
  nixosModulesPath,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/ollama.nix"
    "${inputs.nixpkgs-unstable}/nixos/modules/services/misc/open-webui.nix"
    "${nixosModulesPath}/virtualisation/containers.nix"
    "${nixosModulesPath}/virtualisation/oci-containers.nix"
  ]
  ++ (lib'.flocken.getModules ./.);
}
