{ writeShellApplication, lib }:
package:
writeShellApplication {
  inherit (package) name;
  text = ''
    case "''${CUDA_VISIBLE_DEVICES:-100}" in
      100) CUDA_VISIBLE_DEVICES="$(findgpu)" ;;
    esac
    exec ${lib.getExe package} "$@"
  '';
}
