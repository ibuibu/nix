{inputs, pkgs, ...}: let
  username = "ibuibu";
in {
  nixpkgs = {
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
    ];

    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ./shell
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";

    packages = with pkgs; [
      gh
      ghq
      lazygit
      ripgrep
      bat
      fzf
      exa
      neovim # nighly
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}

