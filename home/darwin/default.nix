{
  inputs,
  pkgs,
  ...
}: let
  username = "hirokiibuka";
in {
  nixpkgs = {
    overlays = [
      inputs.claude-code.overlays.default
    ];

    config = {
      allowUnfree = true;
    };
  };

  imports = [
    ../common
    ./shell
    ./git
  ];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    packages = with pkgs; [
      neovim
    ];

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;

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

      bind [ copy-mode
      bind C-Space copy-mode
      set-option -g mouse on
      bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"
      bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

      bind e setw synchronize-panes on
      bind E setw synchronize-panes off

      setw -g monitor-activity on
      set -g visual-activity on

      set-option -g status-interval 1
      set-option -g status-justify "centre"
      set-option -g status-bg "colour238"
      set-option -g status-fg "colour255"
      set-option -g status-left-length 20
      set-option -g status-left "#[fg=colour255,bg=colour241]Session: #S #[default]"
      set-window-option -g window-status-format " #I: #W "
      set-window-option -g window-status-current-format "#[fg=colour255,bg=colour27,bold] #I: #W #[default]"
      set-option -g status-right-length 60
      set-option -g status-right "#{prefix_highlight}#[fg=colour255,bg=colour241] %m/%d %a %H:%M:%S#[default]"

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

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      set -g pane-border-style fg=White
      set -g pane-active-border-style "bg=default fg=Magenta"

      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-pain-control'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'fcsonline/tmux-thumbs'
      set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
      set -g @prefix_highlight_fg 'colour16'
      set -g @prefix_highlight_bg 'colour220'
      set -g @prefix_highlight_copy_mode_attr 'fg=colour16,bg=colour45,bold'
      # tmux-resurrect: ペイン/ウィンドウ構成とコマンド状態を保存・復元する（保存: Prefix + C-s / 復元: Prefix + C-r）
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      # tmux-continuum: 定期保存とtmux起動時の自動復元を行う
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @continuum-restore 'off'
      set -g @continuum-save-interval '15'
      if-shell '[ ! -d ~/.tmux/plugins/tpm ]' 'run-shell "git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"'
      if-shell '[ -f ~/.tmux/plugins/tmux-thumbs/tmux-thumbs.tmux ]' 'run-shell ~/.tmux/plugins/tmux-thumbs/tmux-thumbs.tmux'
      if-shell '[ -f ~/.tmux/plugins/tpm/tpm ]' 'run-shell ~/.tmux/plugins/tpm/tpm'

      unbind \\
      bind \\ split-window -h -t . -c "#{pane_current_path}"
      bind C-\\ split-window -h -t . -c "#{pane_current_path}"
      bind - split-window -v -t . -c "#{pane_current_path}"
    '';
  };
}
