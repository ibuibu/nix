# 全PRレビュー一括実行

自分がレビューすべき全てのPRを横断的に取得し、1つずつレビューコメントを投稿していく。

## 実行手順

### 0. Organization の指定（必須）

最初にユーザーに確認（AskUserQuestionを使用）：

```
どのorganizationのPRをレビューしますか？
1. すべてのorganization
2. 特定のorganizationのみ
```

「2」を選択した場合、organization名を入力させる（例: `acme-corp`）。

### 1. レビュー待ちPR一覧を取得

organizationが指定されている場合は `--org=ORG` フィルターを追加：

```bash
# organizationが指定されている場合
gh search prs --review-requested=@me --state=open --org=ORG_NAME --json repository,number,title,url,author

# organizationが指定されていない場合（全て）
gh search prs --review-requested=@me --state=open --json repository,number,title,url,author
```

結果例：
```json
[
  {
    "repository": {"owner": "acme-corp", "name": "repo1"},
    "number": 123,
    "title": "feat: 新機能追加",
    "url": "https://github.com/acme-corp/repo1/pull/123",
    "author": {"login": "developer1"}
  },
  {
    "repository": {"owner": "acme-corp", "name": "repo2"},
    "number": 456,
    "title": "fix: バグ修正",
    "url": "https://github.com/acme-corp/repo2/pull/456",
    "author": {"login": "developer2"}
  }
]
```

### 2. ユーザーに一覧を提示

```
レビュー待ちのPRが見つかりました（organization: acme-corp）：

1. acme-corp/repo1 #123 "feat: 新機能追加" by @developer1
   https://github.com/acme-corp/repo1/pull/123

2. acme-corp/repo2 #456 "fix: バグ修正" by @developer2
   https://github.com/acme-corp/repo2/pull/456

どのPRからレビューする？(番号を入力、または 'all' で全て順番に処理)
```

### 3. 選択されたPRをレビュー

各PRについて、以下の手順を実行：

#### 3.1 PR情報の取得

```bash
gh pr view OWNER/REPO#NUMBER --json title,body,files,commits,reviews
```

#### 3.2 差分の取得と分析

```bash
# PRの差分を取得
gh pr diff OWNER/REPO#NUMBER
```

差分を分析し、以下の観点でレビュー：
- コーディング規約の遵守
- ロジックの正確性
- パフォーマンスへの影響
- セキュリティ上の問題
- テストの有無と品質
- ドキュメントの更新

#### 3.3 レビューコメントの提案

AIが差分を分析し、問題点や改善点を洗い出して、以下のフォーマットで提示：

```
【レビュー分析結果】

PR: acme-corp/repo1 #123 "feat: 新機能追加"
Author: @developer1

指摘候補:

1. src/main.rs:45
   問題: エラーハンドリングが不足
   提案: unwrap()ではなく?演算子を使用すべき
   重要度: 高

2. src/lib.rs:120
   問題: 変数名が不明瞭
   提案: 'x' を 'user_count' など意味のある名前に変更
   重要度: 中

3. 全体
   問題: テストが追加されていない
   提案: 新機能に対するユニットテストを追加すべき
   重要度: 高

【総評】
全体的に良い実装ですが、エラーハンドリングとテストの追加が必要です。

コメントを投稿しますか？
1. はい（すべての指摘をコメント）
2. 一部を選択してコメント
3. 編集してからコメント
4. このPRはスキップ
5. Approve（問題なし）
```

#### 3.4 ユーザーの選択に応じて実行

##### オプション1: すべての指摘をコメント

```bash
# 各指摘に対してコメントを投稿
gh pr review OWNER/REPO#NUMBER --comment --body "指摘内容"

# または、まとめてレビューコメントを投稿
gh api graphql -f query='
mutation {
  addPullRequestReview(input: {
    pullRequestId: "PR_ID",
    event: COMMENT,
    comments: [
      {
        path: "src/main.rs",
        position: 45,
        body: "エラーハンドリングが不足しています。unwrap()ではなく?演算子を使用すべきです。"
      }
    ]
  }) {
    pullRequestReview {
      id
    }
  }
}'
```

##### オプション2: 一部を選択してコメント

ユーザーに指摘番号を選択させる（例: `1,3`）

##### オプション3: 編集してからコメント

ユーザーがコメント内容を編集できるようにする

##### オプション4: スキップ

次のPRに進む

##### オプション5: Approve

```bash
gh pr review OWNER/REPO#NUMBER --approve --body "LGTM! 問題ありません。"
```

### 4. 次のPRへ

レビューが完了したら、次のPRに移動して同様に処理。

### 5. 完了報告

全てのPRのレビューが完了したら、サマリーを表示：

```
【レビュー完了】

処理したPR: 5件
- コメント投稿: 3件
- Approve: 1件
- スキップ: 1件

詳細:
✓ acme-corp/repo1 #123 - コメント投稿
✓ acme-corp/repo2 #456 - Approve
- acme-corp/repo3 #789 - スキップ
✓ acme-corp/repo4 #101 - コメント投稿
✓ acme-corp/repo5 #202 - コメント投稿
```

## オプション機能

### 自動化レベルの選択

最初にユーザーに確認：
- **手動モード**: 各PRごとに詳細確認
- **半自動モード**: 明らかな問題のみ指摘、複雑なものは確認
- **通知のみモード**: レビュー待ちPRを通知するだけで、レビューはしない

### レビュー基準のカスタマイズ

特定の観点に絞ってレビュー：
- セキュリティのみ
- パフォーマンスのみ
- コーディング規約のみ
- すべて（デフォルト）

### バッチ処理

複数PRを一度に処理する場合、途中で中断できるようにする。
各PR処理後に「続ける？」と確認を入れる。

## 注意事項

- PRの差分が大きい場合は、ファイル単位で分割してレビュー
- 既に他のレビュアーがコメントしている場合は、その内容も考慮
- レビューコメントは建設的で具体的な内容にする
- 些細な指摘（タイポなど）と重要な指摘（セキュリティ）を区別する
