---
name: gh-create-repo-get
description: GitHubのibuibu配下に新規repoをghで作成し、ghq getでローカルに取得する
---

# gh-create-repo-get

`ibuibu` 配下に新しい GitHub リポジトリを作り、`ghq get` でローカルへ取得するときに使う。

## 使うタイミング

- ユーザーが「新しいrepoを作って」「ghq getまでやって」と依頼したとき
- 既存repoのcloneではなく、新規作成から開始したいとき

## 実行手順

1. リポジトリ名と公開設定を確認する。
2. `gh` で `ibuibu/<repo-name>` を作成する。
3. `ghq get` で `github.com/ibuibu/<repo-name>` を取得する。
4. 取得先パスを確認してユーザーに報告する。

## 詳細フロー

### 1) 入力確認

- repo名（必須）
- 公開設定（`private` / `public`。未指定なら `private`）

### 2) 既存確認

先に repo の存在を確認する。存在する場合は作成をスキップして `ghq get` のみ実行する。

```bash
gh repo view "ibuibu/<repo-name>"
```

### 3) repo作成

存在しない場合のみ実行する。

```bash
gh repo create "ibuibu/<repo-name>" --private --confirm
```

公開repoの場合は `--public` を使う。

### 4) ghq get

```bash
ghq get "github.com/ibuibu/<repo-name>"
```

### 5) 完了確認

```bash
ghq list | rg "^github.com/ibuibu/<repo-name>$"
```

見つかったパスを最終回答で示す。

## 注意点

- `gh auth status` が未ログインなら先にログインを促す。
- 同名repoが既にある場合は作成を行わない。
- デフォルト公開設定は `private` を使う。

## 完了条件

- GitHub上に `ibuibu/<repo-name>` が存在する（または既存repoを確認済み）。
- `ghq get` が成功し、`ghq list` で確認できる。
