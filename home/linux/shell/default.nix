{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    envExtra = ''
      # Load Nix profile if it exists
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        source ~/.nix-profile/etc/profile.d/nix.sh
      fi
    '';
    initContent = ''
      source <(fzf --zsh)
      PATH=$HOME/.command:$PATH
      PATH=$HOME/.local/bin:$PATH
      HISTFILE=~/.zsh_history
      HISTSIZE=200000
      SAVEHIST=200000
      # シェル終了時に履歴ファイルへ追記する（上書きしない）。
      setopt APPEND_HISTORY
      # コマンド実行ごとに履歴ファイルへ即時追記する。
      setopt INC_APPEND_HISTORY
      # 複数の zsh セッション間で履歴を共有する。
      setopt SHARE_HISTORY
      # 直前と同じコマンドは履歴に追加しない。
      setopt HIST_IGNORE_DUPS
      # 履歴保存前に余分な連続スペースを詰める。
      setopt HIST_REDUCE_BLANKS

      function gc() {
        branches=$(git branch --all --sort=-authordate --format="%(refname:short)%09%(authordate:relative)%09%(authorname)" | grep -v HEAD | grep -v origin)
        branch=$(echo "$branches" | column -ts "$(printf '\t')" | fzf)
        git checkout $(echo "$branch" | awk '{print $1}' )
      }

      function gs() {
        p=$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
        if [ -n "$p" ]; then
          cd $(ghq root)/github.com/$p
        fi
      }

      function ws() {
        local selected=$(gwq list --json | jq -r '.[] | "\(.branch)\t\(.path)"' | fzf --with-nth=1 --delimiter='\t')
        if [ -n "$selected" ]; then
          cd "$(echo "$selected" | cut -f2)"
        fi
      }

      function gr() {
        pushd $(ghq root)/github.com/$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
        gho
        popd
      }

      function histbk() {
        mkdir -p ~/.history-backup
        cp ~/.zsh_history ~/.history-backup/zsh_history_backup
      }

      [ -f ~/.zsh_history ] && histbk
    '';
    shellAliases = {
      cat = "bat";
      grep = "rg";
      relogin = "exec $SHELL -l";
      c = "code .";
      de = "cd ~/Desktop";
      v = "nvim";
      ze = "zed";
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
      gpsh = "git push";

      cc = "claude";
      lg = "lazygit";
      tmux-reload = "tmux source-file ~/.config/tmux/tmux.conf";
      ghv = "gh pr view --web";

      l = "eza --icons -1";
      ls = "eza --icons always --classify always";
      la = "eza --icons always --classify always --all ";
      ll = "eza --icons always --long --all --git ";
      tree = "eza --icons always --classify always --tree";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.starship = {
    enable = true;
  };
}
