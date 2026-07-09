{
  pkgs,
  inputs,
  ...
}: let
  codegraph = pkgs.callPackage ./pkgs/codegraph.nix {};
  hunk = inputs.hunk.packages.${pkgs.system}.default;
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
      hunk
    ];
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
  xdg.configFile."herdr/config.toml".source = ./herdr/config.toml;
}
