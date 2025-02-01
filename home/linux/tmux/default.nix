{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 100000;
    keyMode = "vi";
    prefix = "C-Space";
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    extraConfig = ''
      set -g default-command "${pkgs.zsh}/bin/zsh"
      set-option -ag terminal-overrides ',xterm-256color:RGB'

      set -sg escape-time 10

      bind Space copy-mode
      bind C-Space copy-mode
      set-option -g mouse on
      bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -selection clipboard"

      bind e setw synchronize-panes on
      bind E setw synchronize-panes off

      #set-option -g status-position top
      set-option -g status-interval 1
      set-option -g status-justify "centre"
      set-option -g status-bg "colour238"
      set-option -g status-fg "colour255"
      set-option -g status-left-length 20
      set-option -g status-left "#[fg=colour255,bg=colour241]Session: #S #[default]"
      set-window-option -g window-status-format " #I: #W "
      set-window-option -g window-status-current-format "#[fg=colour255,bg=colour27,bold] #I: #W #[default]"
      set-option -g status-right-length 60
      set-option -g status-right "#[fg=colour255,bg=colour241] %m/%d %a %H:%M:%S#[default]"

      set-option -g default-terminal screen-256color

      setw -g window-active-style bg='#16171e'
      setw -g window-style bg='#2B2D3A'

      set -g mouse on
      set -g terminal-overrides 'xterm*:smcup@:rmcup@'

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind ^h select-pane -L
      bind ^j select-pane -D
      bind ^k select-pane -U
      bind ^l select-pane -R

      bind c new-window -c '#{pane_current_path}'
      bind '\' split-window -h -c '#{pane_current_path}'
      bind ^'\' split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g pane-border-style fg=White
      set -g pane-active-border-style "bg=default fg=Magenta"
    '';
    plugins = with pkgs; [
      tmuxPlugins.pain-control
      tmuxPlugins.yank
    ];
  };
}
