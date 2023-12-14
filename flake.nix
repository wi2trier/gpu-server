{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixglhost = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixgl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    systems,
    system-manager,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      flake = let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
          overlays = [
            (final: prev: {
              apptainer = prev.apptainer.override {
                enableNvidiaContainerCli = false;
              };
            })
          ];
        };
        lib = pkgs.lib;
        builder = system-manager.packages.${system}.default;
      in {
        lib = import ./lib.nix nixpkgs.lib;
        packages.${system} = rec {
          default = install;
          install = pkgs.writeShellApplication {
            name = "system-manager-rebuild";
            text = ''
              set -x #echo on
              exec ${lib.getExe builder} "''${1:-switch}" --flake ${self} "''${@:2}"
            '';
          };
          uninstall = pkgs.writeShellApplication {
            name = "system-manager-uninstall";
            text = ''
              set -x #echo on
              exec ${lib.getExe builder} deactivate "''$@"
            '';
          };
          setup = pkgs.writeShellApplication {
            name = "system-manager-setup";
            text = ''
              # only root possible
              if [ "$(id -u)" -ne 0 ]; then
                echo "This script must be run as root" >&2
                exit 1
              fi
              set -x #echo on
              # set up nix
              cp -f ${./etc/nix.conf} /etc/nix/nix.conf
              systemctl restart nix-daemon
              # set up cuda support for oci engines like podman
              nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
              chmod -R 755 /etc/cdi
              # set compute mode to exclusive process (https://stackoverflow.com/a/50056586)
              nvidia-smi -c 3
              # disable default motd
              chmod -x /etc/update-motd.d/*
            '';
          };
          image-jupyter = pkgs.callPackage ./images/jupyter.nix {};
          image-poetry = pkgs.callPackage ./images/poetry.nix {};
        };
        systemConfigs.default = system-manager.lib.makeSystemConfig {
          extraSpecialArgs = {
            inherit inputs;
            mylib = self.lib;
          };
          modules = [
            ./modules
            {
              _module.args.pkgs = lib.mkForce pkgs;
              nixpkgs.hostPlatform = system;
            }
          ];
        };
      };
    };
}
