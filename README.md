# nix

macOS / Linux / WSL の開発環境を Nix + home-manager で管理するリポジトリ。
dotfiles の管理には chezmoi を併用。

## 構成

```
flake.nix                 # エントリポイント
home/
  common/                 # 全OS共通パッケージ (gh, ghq, lazygit, ripgrep, bat, eza, fzf, chezmoi, jq, just)
  darwin/                 # macOS 固有 (aarch64-darwin)
  linux/                  # Linux 汎用 (x86_64-linux)
    git/                  #   git設定 (SSH署名, エディタ等)
    shell/                #   zsh, starship, エイリアス
    mise/                 #   mise (asdf後継)
    tmux/                 #   tmux (xclipでコピー)
  wsl/                    # WSL 固有 (linuxを継承 + 上書き)
    tmux/                 #   tmux (clip.exeでWindowsクリップボードにコピー)
nix-darwin/               # nix-darwin システム設定
chezmoi/                  # chezmoi管理のdotfiles
  dot_claude/             #   Claude Code (CLAUDE.md, settings.json, skills/)
  dot_codex/              #   Codex (AGENTS.md / skills/ を ~/.claude/ へsymlink)
  dot_command/            #   カスタムコマンド (gho等)
  dot_config/             #   アプリ設定 (nvim)
  dot_copilot/            #   Copilot設定 (copilot-instructions.md)
```

### homeConfigurations

| 名前 | システム | 用途 |
|------|---------|------|
| `macos` | aarch64-darwin | macOS |
| `linux` | x86_64-linux | 汎用Linux |
| `wsl` | x86_64-linux | WSL (linux を継承し WSL 固有設定を上書き) |

## セットアップ

### Nix のインストール

```shell
curl -L https://nixos.org/nix/install | sh
```

### 設定の適用

```shell
# WSL/Linux は自動判定される
nix run ".#update"
```

2回目以降は `just` 経由でも実行できます（`nix run ".#update"` + `chezmoi apply` を一括実行）。

```shell
just update
```

### プライベート設定（機密情報）

SSH鍵やプロジェクト固有の設定など、Gitで管理したくない設定は `~/.zshrc.local` に記述します。

```shell
# サンプルファイルをコピー
cp .zshrc.local.example ~/.zshrc.local

# 編集して機密情報を追加
nvim ~/.zshrc.local
```

`~/.zshrc.local` は Nix の zsh 設定から自動的に読み込まれます。

### chezmoi

dotfiles の管理に chezmoi を使用。

```shell
# 初期セットアップ
chezmoi init --apply ibuibu/nix

# よく使うコマンド
chezmoi managed      # 管理対象のファイル一覧
chezmoi add <file>   # ファイルを追加
chezmoi re-add       # 変更済みファイルをリポジトリに反映
chezmoi apply        # 変更を適用
chezmoi diff         # 差分を確認
```

### AIコーディングツール間での skill/指示書の共有

`~/.claude/` を単一の情報源として、他ツールに共有する方針：

| ツール | CLAUDE.md (指示書) | skills/ |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` (本体) | `~/.claude/skills/` (本体) |
| Codex | `~/.codex/AGENTS.md` → symlink | `~/.codex/skills/` → symlink |
| opencode | - | `~/.claude/skills/` を公式サポート |
| GitHub Copilot | `.github/copilot-instructions.md` (別管理) | `~/.claude/skills/` を公式サポート |

opencode / Copilot は `~/.claude/skills/` を直接読むため設定不要。

## その他のコマンド

```shell
# フォーマット
nix fmt <nix-file>

# justfile のレシピ一覧
just
```
