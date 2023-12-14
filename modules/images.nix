{
  pkgs,
  lib,
  ...
}: {
  environment.systemPackages = [
    (pkgs.writeShellApplication {
      # https://github.com/NixOS/nixpkgs/blob/aa9d4729cbc99dabacb50e3994dcefb3ea0f7447/pkgs/build-support/docker/default.nix#L490
      name = "build-container";
      text = ''
        if [ "$#" -lt 1 ]; then
          echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER=.]" >&2
          exit 1
        fi
        cd "''${2:-.}" || exit 1
        BUILDER_SCRIPT="$1-builder.sh"
        ${lib.getExe pkgs.nix} build -o "$BUILDER_SCRIPT" "github:wi2trier/gpu-server#image-$1"
        ./"$BUILDER_SCRIPT" \
          | ${lib.getExe pkgs.pigz} -nTR \
          > "$1.tar.gz"
        rm "$BUILDER_SCRIPT"
      '';
    })
    (pkgs.writeShellApplication {
      name = "build-apptainer";
      text = ''
        if [ "$#" -lt 1 ]; then
          echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER=.]" >&2
          exit 1
        fi
        cd "''${2:-.}" || exit 1
        build-container "$1" # we already changed to the output folder
        ${lib.getExe pkgs.apptainer} build "$1.sif" "docker-archive:$1.tar.gz"
        rm "$1.tar.gz"
      '';
    })
  ];
}
