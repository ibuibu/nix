{
  inputs,
  pkgs,
  ...
}: let
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
    ../common
    ./git
    ./shell
    ./mise
    ./tmux
  ];

  home = {
    username = username;
    homeDirectory = "/home/${username}";

    packages = with pkgs; [
      k6
      xclip
      pass
      neovim # nighly
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
