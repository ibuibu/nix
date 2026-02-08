---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git push:*), Bash(git branch:*), Bash(git log:*), Bash(git diff:*), Bash(gh pr:*)
argument-hint: [commit-message (オプション)]
description: コミット、プッシュ、PR作成を自動化 - プロが毎日使うワークフロー
model: claude-sonnet-4-5-20250929
---

# Commit-Push-PR 自動化ワークフロー

プロの開発者が1日に何度も使う、効率的なGitワークフローを自動化します。

## 現在の状態（事前計算）

- **現在のブランチ**: !`git branch --show-current 2>&1`
- **Git Status**: !`git status --short 2>&1`
- **ステージ済み変更の差分**: !`git diff --staged --stat 2>&1`
- **最近のコミット履歴**: !`git log --oneline --graph -5 2>&1`
- **リモートとの同期状態**: !`git status -sb 2>&1`
- **変更されたファイル一覧**: !`git status --porcelain 2>&1`

## あなたのタスク

以下のステップで、コミット、プッシュ、PR作成を実行してください：

### ステップ1: 変更内容の分析

上記の変更内容を確認し、以下を分析してください：

1. **変更のタイプ**を特定:
   - 新機能追加 (feat)
   - バグ修正 (fix)
   - ドキュメント更新 (docs)
   - リファクタリング (refactor)
   - パフォーマンス改善 (perf)
   - テスト追加 (test)
   - ビルド関連 (build)
   - その他 (chore)

2. **影響範囲**を確認:
   - どのモジュール/コンポーネントが変更されたか
   - フロントエンド/バックエンド/インフラのどれか

### ステップ2: コミットメッセージの生成

**日本語**で、以下の形式のコミットメッセージを生成してください：

```
タイプ(スコープ): 変更の要約（50文字以内）

- 詳細な説明1
- 詳細な説明2
- 詳細な説明3

🤖 Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**引数が指定された場合**:
- `$ARGUMENTS` の内容をコミットメッセージとして使用
- ただし、末尾に Claude Code の署名を追加

### ステップ3: ユーザー確認

生成したコミットメッセージと以下の実行計画を提示し、**ユーザーの承認を待ってください**：

```
📋 実行計画:
1. 未ステージのファイルをステージ: git add .
2. コミット作成: [生成されたメッセージ]
3. リモートへプッシュ: git push -u origin [ブランチ名]
4. Pull Request作成: gh pr create (オプション)

よろしいですか？
```

### ステップ4: Git操作の実行

ユーザーが承認したら、以下を**順番に**実行してください：

1. **ステージング**:
   ```bash
   git add .
   git status --short
   ```

2. **コミット**:
   ```bash
   git commit -m "$(cat <<'EOF'
   [生成されたコミットメッセージ]
   EOF
   )"
   ```

3. **プッシュ**:
   - 現在のブランチをリモートにプッシュ
   - リモートブランチがない場合は `-u origin` で作成
   ```bash
   git push -u origin $(git branch --show-current)
   ```

4. **結果確認**:
   ```bash
   git log -1 --stat
   git status
   ```

### ステップ5: Pull Request作成（オプション）

ユーザーに「Pull Requestを作成しますか？」と尋ね、希望する場合のみ以下を実行：

1. **PR情報の準備**:
   - タイトル: コミットメッセージの1行目
   - 本文: コミットメッセージの詳細部分 + 変更ファイル一覧
   - ベースブランチ: main または develop（確認する）

2. **GitHub CLIでPR作成**:
   ```bash
   gh pr create --title "[タイトル]" --body "$(cat <<'EOF'
   ## 変更内容

   [コミットメッセージの詳細]

   ## 変更ファイル

   [git diff --stat の出力]

   🤖 Generated with Claude Code
   EOF
   )"
   ```

3. **PR URLを表示**:
   - 作成されたPRのURLをユーザーに提示

## 重要な注意事項

1. **安全性最優先**:
   - すべての操作の前にユーザー確認を取る
   - git push --force は絶対に使用しない
   - mainブランチへの直接プッシュは警告する

2. **エラーハンドリング**:
   - コミットやプッシュが失敗した場合、エラー内容を説明
   - マージコンフリクトがある場合は解決方法を提案
   - リモートが最新でない場合は `git pull` を提案

3. **ブランチ戦略の考慮**:
   - 現在のブランチが main/master の場合は警告
   - feature/* や fix/* ブランチの場合は通常通り実行

4. **GitHub CLI の確認**:
   - `gh` コマンドが利用可能か確認
   - 認証されていない場合は `gh auth login` を案内

## 使用例

```bash
# 自動でコミットメッセージを生成
/commit-push-pr

# カスタムメッセージを指定
/commit-push-pr "feat(api): ユーザー認証APIを追加"

# PR作成まで一気に実行
/commit-push-pr
> [生成されたコミットメッセージを確認]
> はい
> [プッシュ完了]
> PRを作成しますか？ はい
> [PR作成完了、URLを表示]
```

## ワークフロー全体像

```
変更 → ステージ → コミット → プッシュ → PR作成
                     ↓
               ユーザー確認
```

すべての段階で透明性を保ち、ibuさんが学習できるよう説明を加えてください。
