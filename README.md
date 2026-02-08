# nix

macOS / Linux / WSL の開発環境を Nix + home-manager で管理するリポジトリ。
dotfiles の管理には chezmoi を併用。

## 構成

```
flake.nix                 # エントリポイント
home/
  common/                 # 全OS共通パッケージ (gh, ghq, lazygit, ripgrep, bat, eza, fzf, chezmoi, jq)
  darwin/                 # macOS 固有 (aarch64-darwin)
  linux/                  # Linux 汎用 (x86_64-linux)
    git/                  #   git設定 (SSH署名, エディタ等)
    shell/                #   zsh, starship, エイリアス
    mise/                 #   mise (asdf後継)
    tmux/                 #   tmux (xclipでコピー)
  wsl/                    # WSL 固有 (linuxを継承 + 上書き)
    tmux/                 #   tmux (clip.exeでWindowsクリップボードにコピー)
nix-darwin/               # nix-darwin システム設定
dot_command/              # カスタムコマンド (chezmoi管理)
dot_config/               # アプリ設定 (nvim, wezterm / chezmoi管理)
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

## その他のコマンド

```shell
# フォーマット
nix fmt <nix-file>
```
