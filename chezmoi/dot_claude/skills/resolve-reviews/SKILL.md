---
description: PRレビューコメント対応
---

# PRレビューコメント対応

現在のブランチに関連するPRの未解決レビューコメントを1つずつ確認し、対応していく。

## 実行手順

### 1. PR情報の取得
```bash
gh pr view --json number,url
```
でPR番号を取得。リポジトリのowner/nameは`gh repo view --json owner,name`で取得。

### 2. 未解決レビュースレッドの取得
GraphQL APIでページネーションを使い、**全スレッド**を取得する。
1ページ目：
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 50) {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes {
              body
              path
              line
            }
          }
        }
      }
    }
  }
}'
```

`hasNextPage`が`true`の場合、`after`引数に`endCursor`の値を渡して次ページを取得する：
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 50, after: "CURSOR") {
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          isResolved
          comments(first: 1) {
            nodes {
              body
              path
              line
            }
          }
        }
      }
    }
  }
}'
```

`hasNextPage`が`false`になるまで繰り返し、全ページの結果から`isResolved: false`のスレッドだけを抽出する。

### 3. 各レビューの処理（すべてresolveされるまで繰り返し）

各未解決レビューについて、以下のスキップ条件に該当する場合は無視して次に進む：
- Copilot以外（人間のレビュアー）からのレビューで、PRオーナーが既にリプライしている場合

スキップしなかった各レビューについて：

1. **レビュー内容を日本語で要約してユーザーに提示**
   - 該当ファイルパスと行番号
   - 指摘内容の和訳
   - 該当コードを読んで文脈を把握

2. **対応要否の考えをユーザーに提示**
   - 技術的な観点から対応すべきか判断
   - 対応する場合の実装方針も提示

3. **ユーザーに確認（AskUserQuestion toolを使う）**
   - 必ずAskUserQuestion toolで選択肢を提示する
   - 選択肢の例：
     - 「対応する」（コード修正して対応）
     - 「〇〇の理由でresolve」（対応不要としてresolve）
   - headerはレビューの要点を短く（例: "CORS設定", "エラー処理"）

4. **ユーザーの判断に応じて実行**

**重要**: resolveするのはCopilotからのレビューのみ。人間のレビュアーからのレビューはリプライのみ行い、resolveはしない。

#### 対応不要の場合
```bash
# リプライ
gh api graphql -f query='mutation { addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: "THREAD_ID", body: "理由" }) { comment { id } } }'

# resolve
gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "THREAD_ID" }) { thread { isResolved } } }'
```

#### 対応する場合
1. コードを修正
2. コンパイル確認（`cargo check --all`等）
3. コミット
4. リプライ＆resolve：
```bash
# リプライ（コミットハッシュ付き）
gh api graphql -f query='mutation { addPullRequestReviewThreadReply(input: { pullRequestReviewThreadId: "THREAD_ID", body: "対応完了: HASH" }) { comment { id } } }'

# resolve
gh api graphql -f query='mutation { resolveReviewThread(input: { threadId: "THREAD_ID" }) { thread { isResolved } } }'
```

### 4. 完了処理
すべてresolveされたら`git push`して完了。
