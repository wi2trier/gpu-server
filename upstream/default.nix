{
  lib',
  nixosModulesPath,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/services/misc/ollama.nix"
    "${inputs.nixpkgs}/nixos/modules/services/misc/open-webui.nix"
    "${nixosModulesPath}/virtualisation/containers.nix"
    "${nixosModulesPath}/virtualisation/oci-containers.nix"
  ]
  ++ (lib'.flocken.getModules ./.);
}
