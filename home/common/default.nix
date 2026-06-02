{pkgs, ...}: let
  codegraph = pkgs.callPackage ./pkgs/codegraph.nix {};
in {
  home = {
    enableNixpkgsReleaseCheck = false;
    packages = with pkgs; [
      gh
      ghq
      lazygit
      ripgrep
      bat
      eza
      fzf
      chezmoi
      jq
      just
      claude-code
      glow
      codegraph
    ];
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
}
