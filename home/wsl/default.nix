{
  lib,
  ...
}: let
  username = "ibuib";
in {
  imports = [
    ../linux
    ./tmux
  ];

  home = {
    username = lib.mkForce username;
    homeDirectory = lib.mkForce "/home/${username}";
  };
}
