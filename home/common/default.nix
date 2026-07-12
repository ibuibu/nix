{
  pkgs,
  inputs,
  ...
}: let
  codegraph = pkgs.callPackage ./pkgs/codegraph.nix {};
  hunkPkg = inputs.hunk.packages.${pkgs.system}.default;
  # bun 製バイナリが nix の glibc 2.42 の ld.so と非互換で segfault するため、
  # Linux ではシステムの ld-linux (glibc 2.39) 経由で起動するようラップする
  hunk =
    if pkgs.stdenv.isLinux
    then
      pkgs.writeShellScriptBin "hunk" ''
        exec /lib64/ld-linux-x86-64.so.2 ${hunkPkg}/bin/hunk "$@"
      ''
    else hunkPkg;
in {
  home = {
    enableNixpkgsReleaseCheck = false;
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
      just
      claude-code
      herdr
      glow
      codegraph
      hunk
    ];
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
  xdg.configFile."herdr/config.toml".source = ./herdr/config.toml;
}
