{...}: {
  programs.tmux.extraConfig = ''
    bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "clip.exe"
    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "clip.exe"
  '';
}
