{ lib', nixosModulesPath, ... }:
let
  nixosModules = [ "/virtualisation/containers.nix" ];
in
{
  imports = (lib'.flocken.getModules ./.) ++ (map (path: nixosModulesPath + path) nixosModules);
}
