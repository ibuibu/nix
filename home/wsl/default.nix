{lib, ...}: let
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

  programs.zsh.shellAliases = {
    de = lib.mkForce "cd '/mnt/c/Users/${username}/OneDrive/デスクトップ'";
  };
}
