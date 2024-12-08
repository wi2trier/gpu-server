{
  writeShellApplication,
  lib,
  nix,
  pigz,
  self,
}:
writeShellApplication {
  # https://github.com/NixOS/nixpkgs/blob/aa9d4729cbc99dabacb50e3994dcefb3ea0f7447/pkgs/build-support/docker/default.nix#L490
  name = "build-container";
  text = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER=.]" >&2
      exit 1
    fi
    cd "''${2:-.}" || exit 1
    BUILDER_SCRIPT="$1-builder.sh"
    ${lib.getExe nix} build --show-trace -o "$BUILDER_SCRIPT" "${self.outPath}#image-$1"
    ./"$BUILDER_SCRIPT" \
      | ${lib.getExe' pigz "pigz"} -nTR \
      > "$1.tar.gz"
    rm "$BUILDER_SCRIPT"
  '';
}
