{
  writeShellApplication,
  lib,
  apptainer,
  build-container,
}:
writeShellApplication {
  name = "build-apptainer";
  text = ''
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 IMAGE_NAME [OUTPUT_FOLDER=.]" >&2
      exit 1
    fi
    cd "''${2:-.}" || exit 1
    ${lib.getExe build-container} "$1" # we already changed to the output folder
    ${lib.getExe apptainer} build "$1.sif" "docker-archive:$1.tar.gz"
    rm "$1.tar.gz"
  '';
}
