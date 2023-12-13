{pkgs, ...}: {
  environment.etc."motd".source = pkgs.writeShellScriptBin "motd" ''
    echo "Welcome to our GPU server!"
    echo "Please check out our documentation:"
    tput bold
    echo "https://github.com/wi2trier/gpu-server"
    tput sgr0
    echo
  '';
}
