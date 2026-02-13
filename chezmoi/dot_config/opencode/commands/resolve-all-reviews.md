# 全リポジトリの未対応レビューを一括処理

自分がレビュー対応すべき全てのPRを横断的に取得し、1つずつ対応していく。

## 実行手順

### 0. Organization の指定（オプション）

最初にユーザーに確認：

```
特定のorganizationに絞り込みますか？
1. すべてのorganization（デフォルト）
2. 特定のorganizationのみ
```

「2」を選択した場合、organization名を入力させる（例: `acme-corp`）。

### 1. レビュー対応が必要なPR一覧を取得

organizationが指定されている場合は `--org=ORG` フィルターを追加：

```bash
# organizationが指定されている場合
gh search prs --author=@me --state=open --review-requested=@me --org=ORG_NAME --json repository,number,title,url

# organizationが指定されていない場合（全て）
gh search prs --author=@me --state=open --review-requested=@me --json repository,number,title,url
```

結果例：
```json
[
  {
    "repository": {"owner": "acme-corp", "name": "repo1"},
    "number": 123,
    "title": "feat: 新機能追加",
    "url": "https://github.com/acme-corp/repo1/pull/123"
  },
  {
    "repository": {"owner": "acme-corp", "name": "repo2"},
    "number": 456,
    "title": "fix: バグ修正",
    "url": "https://github.com/acme-corp/repo2/pull/456"
  }
]
```

### 2. 各PRに対して未解決レビュー数を確認

各PRについて、未解決スレッド数をチェック：

```bash
gh api graphql -f query='
{
  repository(owner: "OWNER", name: "REPO") {
    pullRequest(number: NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
        }
      }
    }
  }
}'
```

未解決スレッドがあるPRのみをリスト化。

### 3. ユーザーに一覧を提示

```
未対応レビューがあるPRが見つかりました（organization: acme-corp）：

1. acme-corp/repo1 #123 "feat: 新機能追加" (未解決: 3件)
   https://github.com/acme-corp/repo1/pull/123

2. acme-corp/repo2 #456 "fix: バグ修正" (未解決: 1件)
   https://github.com/acme-corp/repo2/pull/456

どのPRから対応する？(番号を入力、または 'all' で全て順番に処理)
```

### 4. 選択されたPRに移動して処理

選択されたPRについて：

1. **リポジトリのクローン/移動**
   ```bash
   # リポジトリがローカルにない場合はクローン
   gh repo clone OWNER/REPO ~/path/to/repos/REPO
   
   # ディレクトリに移動
   cd ~/path/to/repos/REPO
   ```

2. **PRのブランチをチェックアウト**
   ```bash
   gh pr checkout NUMBER
   ```

3. **`resolve-reviews` コマンドを実行**
   
   既存の `resolve-reviews` コマンドのロジックを実行：
   - 未解決レビュースレッドを1つずつ取得
   - 各レビューについてユーザーに対応方針を確認
   - コード修正 or 返信のみ
   - 完了したら次のレビューへ
   - 全て完了したら push

4. **再レビュー依頼**
   
   push完了後、ユーザーに確認：
   ```
   レビュアーに再レビュー依頼を送りますか？
   1. はい（再レビュー依頼を送る）
   2. いいえ（スキップ）
   ```
   
   「はい」を選択した場合：
   ```bash
   gh pr ready --undo  # ドラフトの場合のみ（オプショナル）
   gh pr review PR_NUMBER --request-reviewer @REVIEWER_LOGIN
   ```
   
   レビュアーが複数いる場合は全員に再依頼。

5. **次のPRへ**
   
   全てのレビューが解決したら、次のPRに移動して同様に処理。

## オプション機能

### 自動化レベルの選択

ユーザーに確認：
- **手動モード**: 各レビューごとに対応方針を確認
- **半自動モード**: 簡単な修正は自動で対応、複雑なものは確認
- **通知のみモード**: 未対応レビューを通知するだけで、対応はしない

### リポジトリのパス管理

```bash
# 既存のローカルリポジトリパスを検索
find ~/Desktop ~/Documents ~/repos -name ".git" -type d 2>/dev/null | grep -i "REPO_NAME"
```

見つからない場合は `~/repos/REPO_NAME` にクローン。

## 注意事項

- 複数PRを処理する場合、途中で中断できるようにする
- 各PR処理後に「続ける？」と確認を入れる
- リポジトリの切り替え時は、未コミットの変更がないか確認する
