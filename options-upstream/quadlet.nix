{ pkgs, ... }:
{
  environment.etc = {
    "systemd/user-generators/podman-user-generator" = {
      source = "${pkgs.podman}/lib/systemd/user-generators/podman-user-generator";
    };
  };
}
