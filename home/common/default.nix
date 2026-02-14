{pkgs, ...}: {
  home = {
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
      claude-code
    ];
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
}
