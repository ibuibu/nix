{ pkgs, ... }: {

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
    ];
  };
}
