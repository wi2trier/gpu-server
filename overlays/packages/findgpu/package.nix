{
  lib,
  makeBinaryWrapper,
  python3Packages,
  symlinkJoin,
  writers,
}:
let
  findgpu = writers.writePython3Bin "findgpu" {
    libraries = [ python3Packages.nvidia-ml-py ];
    flakeIgnore = [
      "E203"
      "E501"
    ];
  } ./script.py;
in
findgpu.overrideAttrs {
  # Run every binary of pkg through findgpu,
  # so it lands on a free GPU unless CUDA_VISIBLE_DEVICES is set explicitly.
  passthru.wrap =
    pkg:
    symlinkJoin {
      name = "${pkg.name}-findgpu";
      paths = [ pkg ];
      nativeBuildInputs = [ makeBinaryWrapper ];
      postBuild = ''
        for bin in "$out"/bin/*; do
          target="$(readlink -f "$bin")"
          rm "$bin"
          makeWrapper ${lib.getExe findgpu} "$bin" --add-flags "$target"
        done
      '';
      inherit (pkg) meta;
    };
}
