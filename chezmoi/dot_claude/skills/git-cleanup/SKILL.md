---
description: 溜まったローカルブランチとworktreeを、gh でマージ状況を確認しながら分類し、削除対象を1回だけまとめて相談してから消す
---

# git-cleanup

ローカルに溜まったブランチと worktree を整理する。マージ判定は `git branch --merged` と `gh pr list` の2系統で行い、どちらでも裏が取れないものは削除候補に入れずユーザーに委ねる。

## 使うタイミング

`/git-cleanup` で明示的に呼ばれたときだけ実行する。会話の流れから自発的に提案しない。

## 実行手順

### 1. 前提情報の取得

```bash
# デフォルトブランチ（main とは限らない）
DEFAULT=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name')

# リモート追跡refを最新化
git fetch --prune

# ローカルブランチ一覧（追跡状況つき）
git branch -vv

# デフォルトブランチにマージ済みのブランチ
git branch --merged "$DEFAULT"

# worktree一覧
gwq list --json

# worktreeを持つブランチ（削除コマンドの振り分けに使う）
git worktree list --porcelain | grep '^branch ' | sed 's@^branch refs/heads/@@'
```

ブランチ数に対して worktree はごく少数（数百本のブランチに対して10本程度）なのが通常。全ブランチを `gwq` で消せる前提に立たない。

`gh repo view` が失敗したら（未認証・remoteなし等）そこで止めてユーザーに報告する。`main` へのフォールバックはしない。デフォルトが `staging` のリポジトリで誤判定するため。

保護ブランチは `main` `master` `develop` `staging` `release/*` とデフォルトブランチ。分析対象から除外する。

### 2. ブランチごとの調査

保護ブランチ以外の各ブランチについて、以下を取る。ブランチ名は常に `"$branch"` とクォートする。

```bash
# PRの状態（squash/rebase マージでも確実に分かる）
gh pr list --head "$branch" --state all --json number,state,mergedAt --limit 5

# 未pushコミットの有無
git log --oneline "origin/$branch".."$branch"

# デフォルトブランチに無いコミット
git log --oneline "$DEFAULT".."$branch"
```

`origin/$branch..$branch` と `$DEFAULT..$branch` は意味が違う。前者が未push、後者が未マージ。リモートと同期済みでもデフォルトブランチにマージされていないことはあるため、混同しない。

### 3. 分類

| カテゴリ | 条件 | 削除コマンド |
| --- | --- | --- |
| マージ済み | `git branch --merged` に出る | `git branch -d` |
| PRマージ済み | `gh pr list` で `state=MERGED` かつ未pushコミットなし | `git branch -D` |
| 要判断 | リモートが `[gone]` だが MERGED な PR が無い | 提示のみ |
| 未push | `origin/$branch..$branch` に出力がある | 残す |
| ローカルのみ | 追跡なしで固有コミットあり | 残す |
| 同期済み | リモートと一致、未マージ | 残す |

squash マージと rebase マージは `git branch --merged` で検出できないので `-D` が必要。`-d` を先に試して失敗させ、確認を取り直すことはしない。最初から `-D` を提示する。

PR が `CLOSED`（マージされずクローズ）のブランチは削除候補に入れない。作業が捨てられたのか保留なのかコマンドから判断できないため、要判断に置く。

### 4. dirty 判定

`gwq list --json` の各 `path` について `git -C <path> status --porcelain` を実行する。出力があるworktreeは削除候補から外し、変更ファイル名を明示して警告する。

### 5. ゲート1: 分析結果の提示

カテゴリごとの表を1回でまとめて出す。各行に判断根拠（マージ先、PR番号、未pushコミット数）を必ず添える。

そのうえで AskUserQuestion で聞く。

- 推奨分をすべて削除（マージ済み + PRマージ済み）
- カテゴリを選んで削除
- 個別に選ぶ

削除対象が0件なら、ここで「掃除するものは無い」と報告して終了する。質問しない。

### 6. ゲート2: 実行コマンドの確認

実際に流すコマンドをそのまま提示して yes/no を取る。

```
git branch -d fix/typo
git branch -D feat/login
gwq remove -b feat/auth
gwq remove -b --force-delete-branch feat/api
```

削除コマンドは worktree の有無で振り分ける。どちらか一方に寄せることはできない。

| worktree | 使うコマンド |
| --- | --- |
| ある | `gwq rm -b <branch>`（worktreeとブランチを同時に消す） |
| ない | `git branch -d` / `-D` |

- worktree があるブランチに `git branch -d` を使うと「チェックアウト中」で失敗する
- worktree が無いブランチに `gwq rm` を使うと `no worktree found matching pattern` で失敗する
- `gwq rm -b` は squash マージ済みブランチを未マージ扱いで拒否するので `--force-delete-branch` を足す
- worktree を残してブランチだけ消すことはできないので、その組み合わせは提示しない

自信が無いときは `gwq rm --dry-run -b <branch>` で削除対象を確認する。

確認はこの2ゲートだけ。`-D` が必要だからといって追加の確認を挟まない。

### 7. 実行と報告

1コマンドずつ順に実行する。失敗したらエラーを報告して残りを続行する（途中で止めない）。

最後に削除したものと残ったものを一覧で報告する。

## やってはいけない判断

以下はいずれもデータ消失につながるので採用しない。

| 言い訳 | なぜ駄目か |
| --- | --- |
| 古いブランチだから安全 | コミット日時とマージ状況は無関係 |
| reflog で戻せる | 期限切れがあり、復旧手段として案内できない |
| ローカルブランチだから軽い | どこにも push されていない唯一のコピーの可能性がある |
| `[gone]` なら消していい | リモートが消えただけで、未pushコミットは残る |
| デフォルトブランチに無いコミットがある = 未push | 別物。`origin/$branch..$branch` で確認する |
| ユーザーは全部消したそう | 分析を出してから選ばせる |

## 注意点

- `gh` が使えない環境では実行しない。`git log | grep '#[0-9]*'` でPR番号を推測する方式は誤判定するため代替にしない
- worktree の削除は `gwq remove` を使う（`git worktree remove` ではなく、worktree-start と対になる）
- `gwq remove` はパターンを省略すると fuzzy finder が起動して固まる。必ずブランチ名を渡す
- `gwq remove` は dirty なworktreeを拒否する。`-f` は付けない（ゲート1で除外済みのため、ここで force する理由がない）
- リモートブランチは操作しない。ローカルの掃除だけ
- `origin` 以外の remote にマージされたケースは判定できない。該当時は要判断に置く
- `pr-2093` `pr2515` のようなPR番号だけの名前は `gh pr checkout` の残骸で、`gh pr list --head` では一致しない。他人のPRのチェックアウトなので自分の作業ではないが、自動削除はせず要判断にまとめて出す
