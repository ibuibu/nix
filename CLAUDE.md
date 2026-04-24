# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## リポジトリ概要

macOS / Linux / WSL の開発環境を Nix (flake + home-manager) と chezmoi で管理するリポジトリ。

## よく使うコマンド

```shell
# 設定の適用（WSL/Linux は自動判定）
nix run ".#update"

# Nixファイルのフォーマット（alejandra）
nix fmt <nix-file>

# chezmoi: 変更をリポジトリに反映
chezmoi re-add

# chezmoi: リポジトリからホームに適用
chezmoi apply
```

## アーキテクチャ

### Nix 構成

`flake.nix` がエントリポイント。3つの homeConfigurations を定義：

- **macos** (aarch64-darwin): `home/darwin/` → `home/common/`
- **linux** (x86_64-linux): `home/linux/` → `home/common/` + git/shell/mise/tmux サブモジュール
- **wsl** (x86_64-linux): `home/wsl/` → `home/linux/` を継承し WSL 固有設定（tmux の clip.exe 等）を上書き

継承関係: `wsl → linux → common`、`darwin → common`

`nix-darwin/` は macOS のシステムレベル設定（Dock, Finder 等）。darwinConfigurations 名は `MacBookProM2`。

### プラットフォーム別の注意

- ユーザー名: macOS=`hirokiibuka`, Linux=`ibuibu`, WSL=`ibuib`（WSL は `lib.mkForce` で上書き）
- Overlay: `neovim-nightly` は Linux/WSL のみ、`claude-code` は全プラットフォーム
- クリップボード: macOS=`pbcopy`, Linux=`xclip`, WSL=`win32yank.exe`

### chezmoi 構成

`chezmoi/` 配下が chezmoi 管理の dotfiles。`dot_` プレフィックスが `.` に変換される：

- `dot_claude/` → `~/.claude/`（Claude Code 設定: `CLAUDE.md`, `settings.json`, `skills/`）
- `dot_codex/` → `~/.codex/`（`AGENTS.md` と `skills/` は `~/.claude/` へ symlink）
- `dot_copilot/` → `~/.copilot/`（Copilot の `copilot-instructions.md`）
- `dot_config/nvim/` → `~/.config/nvim/`（LazyVim ベースの Neovim 設定）
- `dot_command/` → `~/.command/`（カスタムスクリプト、PATH に追加済み）

### AIツール間の skill / 指示書共有

`~/.claude/` を単一の情報源として扱う：

- **Codex**: `~/.codex/AGENTS.md` と `~/.codex/skills/` を `~/.claude/CLAUDE.md` / `~/.claude/skills/` への symlink で共有（chezmoi の `symlink_` プレフィックス）
- **opencode**: `~/.claude/skills/<name>/SKILL.md` を公式サポート（[Docs](https://opencode.ai/docs/skills/)）
- **GitHub Copilot**: Personal skills として `~/.claude/skills/`、Project skills として `.claude/skills/` を公式サポート（[Docs](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)）

→ skill を `~/.claude/skills/` に置けば 4ツールすべてで使える。

## Nix 編集時の注意

- nixpkgs は unstable チャンネルを使用
- neovim は nightly overlay を使用
- フォーマッタは alejandra
