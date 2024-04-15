{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [ tmux ];
    etc."tmux.conf".text = ''
      new-session
    '';
  };
}
