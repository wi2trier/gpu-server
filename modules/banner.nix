{pkgs, ...}: {
  environment.etc."banner".text = ''
    Welcome to our GPU server! Please check out the documentation:
    https://github.com/wi2trier/gpu-server

  '';
}
