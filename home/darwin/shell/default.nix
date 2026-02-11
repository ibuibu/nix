{pkgs, lib, ...}: {
  programs.zsh = {
    enable = true;
    # Zimが提供するので無効化
    enableCompletion = false;
    autosuggestion.enable = false;
    syntaxHighlighting.enable = false;

    envExtra = ''
      # Load Nix profile if it exists
      if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
        source ~/.nix-profile/etc/profile.d/nix.sh
      fi

      # Editor
      export VISUAL='nvim'
      export EDITOR='nvim'
      export LC_CTYPE="en_US.UTF-8"

      # History
      export HISTSIZE=10000
      export SAVEHIST=10000
      export HISTFILE=~/.zsh_history

      # PATH (基本設定のみ、Nixは initContent で最優先に設定)
      export PATH=$HOME/.command:$PATH
      export PATH=$HOME/.local/bin:$PATH
      export PATH=$HOME/.opencode/bin:$PATH
      
      # pnpm
      export PNPM_HOME="$HOME/Library/pnpm"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
    '';

    initContent = lib.mkMerge [
      # メインの設定
      ''
        # Homebrew
        eval $(/opt/homebrew/bin/brew shellenv)
        
        # Nix PATHを最優先に（Homebrewの後に実行して上書き）
        export PATH=~/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH
        
        # vi mode
        bindkey -v

        # fzf
        source <(fzf --zsh)
        export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'

        # Key bindings
        bindkey "^[[3~" delete-char
        bindkey "\e[1~" beginning-of-line
        bindkey "\e[4~" end-of-line

        # Options
        setopt HIST_IGNORE_ALL_DUPS
        setopt auto_pushd
        setopt pushd_ignore_dups

        # Google Cloud SDK (PATH only, completion after Zim)
        if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then 
          source "$HOME/google-cloud-sdk/path.zsh.inc"
        fi
        export CLOUDSDK_PYTHON_SITEPACKAGES=1

        # mise
        eval "$(mise activate zsh)"

        # fzf
        [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

        # ghcup
        [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env"

        # Zim Framework
        ZIM_HOME=''${ZDOTDIR:-''${HOME}}/.zim
        if [[ ! -e ''${ZIM_HOME}/zimfw.zsh ]]; then
          if (( ''${+commands[curl]} )); then
            curl -fsSL --create-dirs -o ''${ZIM_HOME}/zimfw.zsh \
                https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
          else
            mkdir -p ''${ZIM_HOME} && wget -nv -O ''${ZIM_HOME}/zimfw.zsh \
                https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
          fi
        fi
        if [[ ! ''${ZIM_HOME}/init.zsh -nt ''${ZIM_CONFIG_FILE:-''${ZDOTDIR:-''${HOME}}/.zimrc} ]]; then
          source ''${ZIM_HOME}/zimfw.zsh init
        fi
        source ''${ZIM_HOME}/init.zsh

        # Zim configuration
        ZSH_AUTOSUGGEST_MANUAL_REBIND=1
        ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

        # zsh-history-substring-search
        zmodload -F zsh/terminfo +p:terminfo
        for key ('^[[A' '^P' ''${terminfo[kcuu1]}) bindkey ''${key} history-substring-search-up
        for key ('^[[B' '^N' ''${terminfo[kcud1]}) bindkey ''${key} history-substring-search-down
        for key ('k') bindkey -M vicmd ''${key} history-substring-search-up
        for key ('j') bindkey -M vicmd ''${key} history-substring-search-down
        unset key

        # Completions (AFTER Zim completion module)
        fpath=("$HOME/.zsh/completions" $fpath)
        
        # Google Cloud SDK completion (after Zim)
        if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then 
          source "$HOME/google-cloud-sdk/completion.zsh.inc"
        fi
        
        # gh completion (after Zim)
        eval "$(gh completion -s zsh)"

        # Load custom functions
        [ -f ~/.zsh/functions.zsh ] && source ~/.zsh/functions.zsh

        # Load local configuration (private, not in git)
        [ -f ~/.zshrc.local ] && source ~/.zshrc.local
      ''
    ];

    shellAliases = {
      # Basic
      relogin = "exec $SHELL -l";
      c = "code .";
      de = "cd ~/Desktop";
      v = "nvim";
      vzsh = "nvim ~/.zshrc";
      vinit = "pushd ~/.config/nvim; nvim init.lua; popd";
      
      # macOS specific
      rm = "trash -F";
      bell = "afplay /System/Library/Sounds/Hero.aiff";

      # File listing (eza)
      l = "eza --icons -1";
      ls = "eza --icons always --classify always";
      la = "eza --icons always --classify always --all";
      ll = "eza --icons always --long --all --git";
      tree = "eza --icons always --classify always --tree";

      # Git
      g = "git";
      gcb = "git checkout -b";
      gpl = "git pull";
      gitprune = "git branch --merged | grep -v '*' | xargs -I{} git branch -d {} && git fetch --prune";

      # Docker
      docker-compose = "docker compose";
      dc = "docker compose";
      dps = "docker ps";
      dcu = "docker compose up -d";
      dcp = "docker compose ps";
      dcd = "docker compose down";
      dcda = "docker stop $(docker ps -q)";

      # Tools
      o = "opencode";
      lg = "lazygit";
      ghv = "gh pr view --web";
    };
  };

  home.file.".zsh/functions.zsh".text = ''
    # Git branch checkout with fzf
    function gc() {
      branches=$(git branch --all --format="%(refname:short)%09%(authordate:relative)%09%(authorname)" | grep -v HEAD | grep -v origin)
      branch=$(echo "$branches" | column -ts "$(printf '\t')" | fzf)
      git checkout $(echo "$branch" | awk '{print $1}' )
    }

    # ghq select with fzf
    function gs() {
      p=$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
      if [ -n "$p" ]; then
        cd $(ghq root)/github.com/$p
      fi
    }

    # ghq + gho
    function gr() {
      pushd $(ghq root)/github.com/$(ghq list | cut -d "/" -f 2,3 | sort | fzf)
      gho
      popd
    }

    # Check SSL certificate
    function chkssl() {
      openssl s_client -connect ''${1}:443 -servername ''${1} 2>/dev/null < /dev/null | openssl x509 -noout -dates
    }

    # Timer with notification
    function timer() {
      seconds=$1
      echo "Timer set!! $(date +%H:%M:%S) -> $(date -v+''${seconds}S +%H:%M:%S)\n"
      sleep $1
      osascript -e 'on run argv
        display notification item 1 of argv sound name "Glass" with title "タイマー"
      end run' -- "$2"
    }

    # Run command with notification
    function wn() {
      "$@"
      osascript -e 'on run argv
        display notification item 1 of argv sound name "Glass" with title "お知らせ"
      end run' -- "$*"
    }

    # Convert aif to mp3
    function aiftomp3() {
      ffmpeg -i ''${1} -f mp3 -b:a 192k $(basename ''${1} .aif).mp3
    }
  '';
}
