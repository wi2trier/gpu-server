{pkgs, ...}: {
  environment.etc."motd".text = ''
    Welcome to our GPU server! Please check out our documentation:

    https://github.com/wi2trier/gpu-server

    If you encounter any problems, feel free to open an issue on GitHub or contact your supervisor.
  '';
}
