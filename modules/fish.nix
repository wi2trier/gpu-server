# https://github.com/numtide/system-manager/blob/main/nix/modules/environment.nix
{pkgs, ...}: {
  environment.etc."fish/conf.d/wi2-system-manager-path.fish".source = pkgs.writeTextFile {
    name = "wi2-system-manager-path.fish";
    executable = true;
    text = ''
      set -gx PATH "/run/system-manager/sw/bin" $PATH
    '';
  };
}
