{
  inputs,
  pkgs,
  ...
}: let
  username = "hirokiibuka";
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ../common
    ./shell
    ./git
  ];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    packages = with pkgs; [
      neovim
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
