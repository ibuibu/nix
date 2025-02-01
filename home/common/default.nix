{ pkgs, ... }: {

  imports = [
    ./git
  ];

  home = {
    packages = with pkgs; [
      gh
      ghq
      lazygit
      ripgrep
      bat
      eza
      fzf
      vscode
      chezmoi
    ];
  };
}
