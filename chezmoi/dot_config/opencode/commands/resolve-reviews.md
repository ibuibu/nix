# PRレビューコメント対応

現在のブランチに関連するPRの未解決レビューコメントを1つずつ確認し、対応していく。

## 実行手順

### 1. PR情報の取得
```bash
gh pr view --json number,url
```
でPR番号を取得。リポジトリのowner/nameは`gh repo view --json owner,name`で取得。

### 2. 未解決レビュースレッドの取得
GraphQL APIで`isResolved: false`のスレッドを取得：
```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 50) {
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

### 3. 各レビューの処理（すべてresolveされるまで繰り返し）

各未解決レビューについて：

1. **レビュー内容を日本語で要約してユーザーに提示**
   - 該当ファイルパスと行番号
   - 指摘内容の和訳
   - 該当コードを読んで文脈を把握

2. **対応要否の考えをユーザーに提示**
   - 技術的な観点から対応すべきか判断
   - 対応する場合の実装方針も提示

3. **ユーザーに確認**
   - 「対応する？それとも〇〇の理由でresolve？」のように聞く

4. **ユーザーの判断に応じて実行**

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
すべてresolveされたら`git push`を実行。

### 5. 再レビュー依頼
push完了後、ユーザーに確認：

```
レビュアーに再レビュー依頼を送りますか？
1. はい（再レビュー依頼を送る）
2. いいえ（スキップ）
```

「はい」を選択した場合：
```bash
gh pr ready --undo  # ドラフトの場合のみ（オプショナル）
gh pr review REQUEST_NUMBER --request-reviewer @REVIEWER_LOGIN
```

レビュアーが複数いる場合は全員に再依頼。
