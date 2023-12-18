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
    flocken = {
      url = "github:mirkolenz/flocken/v2";
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
        lib = nixpkgs.lib;
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
        builder = system-manager.packages.${system}.default;
      in {
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
          image-base = pkgs.callPackage ./images/base.nix {};
          image-jupyter = pkgs.callPackage ./images/jupyter.nix {base = image-base;};
          image-poetry = pkgs.callPackage ./images/poetry.nix {base = image-base;};
        };
        systemConfigs.default = system-manager.lib.makeSystemConfig {
          extraSpecialArgs = {
            inherit inputs self;
            mylib = {
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
      };
    };
}
