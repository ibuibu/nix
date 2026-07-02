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
      herdr
      glow
      codegraph
    ];
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
  xdg.configFile."herdr/config.toml".source = ./herdr/config.toml;
}
