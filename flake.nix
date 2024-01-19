{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixglhost = {
      url = "github:numtide/nix-gl-host";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flocken = {
      url = "github:mirkolenz/flocken/v2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    system-manager,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      lib,
      system,
      pkgs,
      ...
    }: {
      _module.args = {
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            cudaSupport = true;
          };
          overlays = lib.singleton (
            final: prev: {
              apptainer = prev.apptainer.override {
                enableNvidiaContainerCli = false;
              };
              system-manager = inputs.system-manager.packages.${system}.default;
            }
          );
        };
      };
      systems = lib.singleton system;
      persystem.packages = rec {
        default = install;
        install = pkgs.writeShellApplication {
          name = "system-manager-rebuild";
          text = ''
            set -x #echo on
            exec ${lib.getExe pkgs.system-manager} "''${1:-switch}" --flake ${self} "''${@:2}"
          '';
        };
        uninstall = pkgs.writeShellApplication {
          name = "system-manager-uninstall";
          text = ''
            set -x #echo on
            exec ${lib.getExe pkgs.system-manager} deactivate "''$@"
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
        image-base = pkgs.callPackage ./images/base.nix {};
        image-jupyter = pkgs.callPackage ./images/jupyter.nix {base = image-base;};
        image-poetry = pkgs.callPackage ./images/poetry.nix {base = image-base;};
      };
      flake.systemConfigs.default = system-manager.lib.makeSystemConfig {
        extraSpecialArgs = {
          inherit inputs self;
          lib' = {
            flocken = inputs.flocken.lib;
          };
        };
        modules = [
          ./modules
          {
            _module.args.pkgs = lib.mkForce pkgs;
            nixpkgs.hostPlatform = system;
          }
        ];
      };
    });
}
