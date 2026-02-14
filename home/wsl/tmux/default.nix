{...}: {
  programs.tmux.extraConfig = ''
    bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "win32yank.exe -i"
    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "win32yank.exe -i"
  '';
}
