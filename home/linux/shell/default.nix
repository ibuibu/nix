{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra = ''
      source <(fzf --zsh)
      PATH=$HOME/.command:$PATH
      function gc() {
        branches=$(git branch --all --format="%(refname:short)%09%(authordate:relative)%09%(authorname)" | grep -v HEAD | grep -v origin)
        branch=$(echo "$branches" | column -ts "$(printf '\t')" | fzf)
        git checkout $(echo "$branch" | awk '{print $1}' )
      }

      function gs() {
        p=$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
        if [ -n "$p" ]; then
          cd $(ghq root)/github.com/$p
        fi
      }

      function gr() {
        pushd $(ghq root)/github.com/$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
        gho
        popd
      }
    '';
    shellAliases = {
      cat = "bat";
      grep = "rg";
      relogin = "exec $SHELL -l";
      c = "code .";
      de = "cd ~/Desktop";
      v = "nvim";
      vzsh = "nvim ~/.zshrc";
      vinit = "pushd ~/.config/nvim; nvim init.lua; popd";
      gitprune = "git branch --merged | grep -v '*' | xargs -I{} git branch -d {} && git fetch --prune";
      dps = "docker ps";
      dcu = "docker compose up -d";
      dcp = "docker compose ps";
      dcd = "docker compose down";
      dcda = "docker stop $(docker ps -q)";

      g = "git";
      gcb = "git checkout -b";
      gpl = "git pull";

      lg = "lazygit";
      ghv = "gh pr view --web";

      l = "eza --icons -1";
      ls = "eza --icons always --classify always";
      la = "eza --icons always --classify always --all ";
      ll = "eza --icons always --long --all --git ";
      tree = "eza --icons always --classify always --tree";
    };
  };

  programs.starship = {
    enable = true;
  };
}
