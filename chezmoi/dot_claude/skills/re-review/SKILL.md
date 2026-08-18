---
description: 自分が出したPRレビューコメントの反映状況を確認してresolveし、あらためて全体を再レビューして「前回見落とし」「新規発生」に分けて1件ずつ相談する
---

# re-review

自分がレビュアーとして出したPRコメントの再レビューを行う。前半で既存コメントの反映確認とresolve、後半で改めての総ざらいレビューを行う。

## 前提

- 自分は **レビュアー** 側（PRオーナーではない）。
- CLAUDE.md の「PRレビュー」セクションに従う。相談フェーズ中はAPIを呼ばず、承認されたコメントをメモリ上に溜め、最後にまとめて1回だけ pending review を POST する。submitはしない。
- レビューコメントはですます調、太字なし、冒頭1文で用件。

## 1. 基本情報の取得

```bash
gh pr view <PR番号 or 省略> --json number,url,headRefOid,baseRefName,author
gh repo view --json owner,name
gh api user --jq .login   # 自分のlogin
```

PR番号が引数で渡されていればそれを使う。渡されていなければカレントブランチのPRを使い、どのPRを見るのかユーザーに提示してから進める。

## 2. 前回レビュー時点のcommitを特定

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviews(last: 100) {
        nodes {
          author { login }
          submittedAt
          commit { oid }
          state
        }
      }
    }
  }
}'
```

自分のloginのレビューのうち最新のものの `commit.oid` を `PREV`、`headRefOid` を `HEAD` とする。以降このPREVを「前回レビュー時点」として扱う。

自分のレビューが1件も無い場合は再レビューではないので、その旨を伝えて中断する（通常のレビューを行うか確認する）。

```bash
git fetch origin
git log --oneline PREV..HEAD          # 前回以降のcommit
git diff PREV...HEAD --stat           # 前回以降の差分の範囲
```

PREV がローカルに無い場合は `git fetch origin PREV` で取得する。

## 3. 自分の既存コメントを全取得

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 50) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes { databaseId author { login } body path line originalLine createdAt }
          }
        }
      }
    }
  }
}'
```

`hasNextPage` が `true` の間、`after: "CURSOR"` を付けて全ページ取得する。

対象は「先頭コメントの author が自分」かつ「isResolved が false」のスレッドのみ。

## 4. 反映状況の確認（くまなく）

各対象スレッドについて、推測せず必ず現在のコードを読んで判定する。

1. スレッドの指摘内容と対象ファイル・行を把握する
2. 現在のHEADの該当ファイルを読む（行がずれている・isOutdatedの場合は、指摘対象の関数やロジックを探して追う）
3. 指摘が同種の箇所に複数あった場合は、コメントした箇所だけでなく同じパターンの箇所も `grep` で確認する
4. 判定を次の3つに分ける
   - 反映済み: 指摘どおりに直っている
   - 未反映: 手が入っていない、または直っていない
   - 部分反映: 一部だけ直っている、別の形で残っている

判定根拠として、該当ファイルの現在のコード（該当行）を必ずユーザーに示す。

### 反映済みのスレッドの処理

反映済みと判断したスレッドは、まとめてユーザーに一覧提示して確認を取る（AskUserQuestion）。承認されたものだけresolveする。

お礼や確認完了のリプライは付けず、resolveだけを行う。

```bash
gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "THREAD_ID" }) { thread { isResolved } } }'
```

未反映・部分反映のスレッドはresolveしない。後半の指摘リストに「未対応の既存指摘」として残し、必要ならスレッドにリマインドのリプライを出すかユーザーに確認する。

## 5. 改めて総ざらいレビュー

PR全体（`git diff BASE...HEAD`）を対象に、前回のコメントに引きずられず1からレビューする。既存コメントで指摘済みの内容は除外する。

観点:

- 正しさ（境界値、null/空、エラー処理、非同期、競合状態）
- リポジトリの CLAUDE.md / `.claude/rules/` のルール違反
- 既存実装との一貫性、車輪の再発明
- テストの網羅性
- セキュリティ（入力検証、権限チェック、秘密情報の露出）

規模が大きい場合は観点ごとにサブエージェント（reviewer）を並列で走らせてよい。ただし最終的な指摘の採否は必ず自分で確認する。

## 6. グルーピング

見つかった各指摘を、該当コードが前回レビュー時点で既に存在していたかで分類する。

```bash
# 該当行が前回以降の差分に含まれるか
git diff PREV...HEAD -- <path>
# 該当行がPREV時点で既にあったか
git show PREV:<path> | sed -n '<開始>,<終了>p'
# 該当行を導入したcommit
git log --oneline PREV..HEAD -- <path>
git blame -L <開始>,<終了> HEAD -- <path>
```

- 前回見落とし: PREV時点にも同じ問題が存在していた
- 新規発生: PREV以降のcommitで入った、または既存コードでもPREV以降の変更によって初めて問題になった

どちらか判断がつかない場合は、根拠を添えて新規発生ではなく「判定保留」として提示し、ユーザーに判断を仰ぐ。

## 7. 1件ずつ相談

「未対応の既存指摘」「前回見落とし」「新規発生」の順に、1件ずつ AskUserQuestion で確認する。この間はAPIを一切呼ばない。

各件で提示するもの:

- 分類（前回見落とし / 新規発生）
- ファイルパスと行番号
- 該当コード
- 何が問題か、どうしてほしいか（コメント本文の案。ですます調、冒頭1文で用件、太字なし）
- 新規発生の場合は、どのcommitで入ったか

選択肢は「コメントする」「コメントしない（理由）」を基本とし、header は指摘の要点を短く書く（例: "null処理", "N+1"）。

AskUserQuestion の直前にテキストを出す場合は末尾に空行を3行入れる。

承認されたコメントは path / line / body をメモリ上に溜める。

## 8. まとめてpending reviewをPOST

全件の相談が終わったら、承認された分をまとめて1回だけPOSTする。既存のpending reviewがある場合はコメントを取得・マージしてから削除→再作成する。

```bash
REVIEW_ID=$(gh api repos/OWNER/REPO/pulls/NUMBER/reviews \
  --jq '.[] | select(.user.login=="MY_LOGIN") | select(.state=="PENDING") | .id')
if [ -n "$REVIEW_ID" ]; then
  gh api repos/OWNER/REPO/pulls/NUMBER/reviews/$REVIEW_ID/comments \
    --jq '[.[] | {path, line, side: "RIGHT", body}]' > existing_comments.json
  gh api repos/OWNER/REPO/pulls/NUMBER/reviews/$REVIEW_ID --method DELETE
fi

gh api repos/OWNER/REPO/pulls/NUMBER/reviews --method POST --input - <<'EOF'
{
  "body": "",
  "comments": [
    { "path": "file.rs", "line": 42, "side": "RIGHT", "body": "コメント内容" }
  ]
}
EOF
```

`event` フィールドは省略する（省略 = PENDING）。

## 9. 最後の報告

次をまとめて報告する。

- resolveしたスレッド数と内容
- 未反映のまま残したスレッド
- 前回見落とし / 新規発生それぞれのコメント件数
- 相談の結果コメントしなかった件と理由

submitはユーザーがGitHub GUIで行うため、こちらでは行わない。PRのURLを添えて終わる。
