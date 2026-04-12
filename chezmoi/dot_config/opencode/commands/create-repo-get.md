---
name: create-repo-get
description: GitHubの対象org/ユーザーを選んで新規repoを作成し、ghq getまで実行する
---

# create-repo-get

対象の org/ユーザーを選んで新しい GitHub リポジトリを作成し、`ghq get` でローカルに取得する。

## 引数

- `repo`: リポジトリ名（必須）
- `owner`: org/ユーザー名（省略時は候補から選択）
- `visibility`: `private` または `public`（省略時は `private`）

## 実行手順

1. 引数を確認する。
2. `gh auth status` でログイン状態を確認する。
3. `gh` で owner候補（ログインユーザー + 所属org）を取得する。
4. `owner` 未指定なら候補から選択させる。
5. `gh repo view "<owner>/<repo>"` で既存確認する。
6. 未存在なら `gh repo create` を実行する。
7. `ghq get "github.com/<owner>/<repo>"` を実行する。
8. 取得結果を表示して完了する。

## 実行コマンド

```bash
# 1) ログイン確認
gh auth status

# 2) owner候補を取得（ログインユーザー + 所属org）
gh api user --jq '.login'
gh api user/orgs --jq '.[].login'

# 3) 既存確認（存在すれば作成をスキップ）
gh repo view "<owner>/<repo>"

# 4) repo作成（未存在時のみ）
gh repo create "<owner>/<repo>" --private --confirm
# publicの場合
gh repo create "<owner>/<repo>" --public --confirm

# 5) 取得
ghq get "github.com/<owner>/<repo>"

# 6) 確認
ghq list | rg "^github.com/<owner>/<repo>$"
```

## 例

```text
/create-repo-get repo=my-new-tool
/create-repo-get repo=my-public-lib owner=ibuibu visibility=public
```

## 注意

- `owner` 未指定時は、取得した候補を提示してユーザーに選ばせる。
- 同名repoが既に存在する場合は作成せず `ghq get` のみ行う。
- `gh auth status` が失敗した場合は `gh auth login` を案内して終了する。
