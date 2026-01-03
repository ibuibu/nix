# nix

**Note**: macOSではnixを使用しなくなりました。現在はchezmoiでドットファイルのみを管理しています。Linuxでは引き続きnixを使用しています。

## chezmoi

dotfilesの管理にchezmoiを使用しています。

### 初期セットアップ

```shell
# このリポジトリをchezmoiのソースディレクトリとして使用
chezmoi init --apply ibuibu/nix
```

### よく使うコマンド

```shell
# 管理対象のファイル一覧を表示
chezmoi managed

# ファイルを追加
chezmoi add ~/.config/nvim/init.lua

# 変更を適用
chezmoi apply

# 差分を確認
chezmoi diff

# 編集
chezmoi edit ~/.config/nvim/init.lua
```

---

## Nix

### Update

```shell
nix run ".#update"
```

### format

```shell
nix fmt <nix-file>
```

### check generation

```shell
nix run "nixpkgs#home-manager" -- generations
```
