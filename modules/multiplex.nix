{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      tmux
      zellij
    ];
    etc."tmux.conf".text = ''
      new-session
    '';
  };
}
