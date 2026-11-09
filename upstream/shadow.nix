# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/programs/shadow.nix
{ lib, pkgs, ... }:
{
  # File capabilities instead of setuid root, like the NixOS module.
  security.wrappers =
    lib.mapAttrs
      (name: capabilities: {
        inherit capabilities;
        owner = "root";
        group = "root";
        source = "${pkgs.shadow.out}/bin/${name}";
      })
      {
        newuidmap = "cap_setuid+ep";
        newgidmap = "cap_setgid+ep";
      };
}
