{
  writeShellApplication,
  lib,
  findgpu,
}:
package:
writeShellApplication {
  name = package.pname;
  text = ''
    case "''${CUDA_VISIBLE_DEVICES:-100}" in
      100) CUDA_VISIBLE_DEVICES="$(${lib.getExe findgpu})" ;;
    esac
    exec ${lib.getExe package} "$@"
  '';
}
