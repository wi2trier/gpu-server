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
          echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER]" >&2
          exit 1
        fi
        ${lib.getExe pkgs.nix} run "github:wi2trier/gpu-server#image-$1" \
          | ${lib.getExe pkgs.pigz} -nTR \
          > "''${2:-.}/$1.tar.gz"
      '';
    })
    (pkgs.writeShellApplication {
      name = "build-apptainer";
      text = ''
        if [ "$#" -lt 1 ]; then
          echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER]" >&2
          exit 1
        fi
        ${lib.getExe pkgs.nix} run "github:wi2trier/gpu-server#image-$1" \
          | ${lib.getExe pkgs.pigz} -nTR \
          | ${lib.getExe pkgs.apptainer} build "''${2:-.}/$1.sif" docker-archive:/dev/stdin
      '';
    })
  ];
}
