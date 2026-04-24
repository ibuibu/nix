---
description: gwqでworktreeを切り、.envとsettings.local.jsonをコピーし、plan-xxx.mdを配置して別ターミナルで作業開始できる状態を作る
---

# worktree-start

`gwq add -b` で新規ブランチ付きworktreeを作り、現在のrepoから `.env` と `.claude/settings.local.json` をコピーし、作業計画を `plan-xxx.md` として配置する。別ターミナルでworktreeに `cd` すればすぐ作業開始できる状態にする。

## 使うタイミング

- `/worktree-start` で明示的に呼ばれたとき
- 「worktree切って作業準備して」「別のworktreeで作業したい」等の自然言語で依頼されたとき

## 実行手順

### 1. 作業内容の確認

直前の会話に作業内容の文脈があれば、それを使う。
文脈がなければユーザーに「何をやるか」を聞く。

### 2. ブランチ名の推測

作業内容から以下を推測する：

- **prefix**: 内容に応じて `feat/` `fix/` `chore/` `docs/` `refactor/` などから選ぶ
  - 新機能・機能追加 → `feat/`
  - バグ修正 → `fix/`
  - ドキュメント → `docs/`
  - リファクタリング → `refactor/`
  - その他雑務 → `chore/`
- **xxx部分**: 作業内容を簡潔に表すkebab-case

例: 「認証のAPIを追加」→ `feat/auth-api`

### 3. plan-xxx.md ドラフト作成

作業内容に応じて構造を決める。軽い作業なら TODO 箇条書きだけ、複雑なら背景・ゴール・TODOなどセクション分け。

ファイル名は `plan-<xxx>.md`（xxxはブランチ名の xxx 部分と同じ）。

### 4. ユーザー確認（まとめて一度だけ）

ブランチ名（`<prefix>/<xxx>`）と plan のドラフト内容をまとめて提示し、AskUserQuestion で「この内容で進める？」と確認する。

**この確認前には `gwq add` を実行しない**。

### 5. worktree作成と準備

確認が取れたら以下を順に実行：

```bash
# worktree作成（新規ブランチ付き）
gwq add -b <prefix>/<xxx>

# worktreeパスを取得
WT_PATH=$(gwq get <prefix>/<xxx>)

# .env があればコピー
[ -f .env ] && cp .env "$WT_PATH/"

# .claude/settings.local.json があればコピー
[ -f .claude/settings.local.json ] && mkdir -p "$WT_PATH/.claude" && cp .claude/settings.local.json "$WT_PATH/.claude/"

# plan を配置
# (Writeツールで $WT_PATH/plan-<xxx>.md に書き出す)
```

**重要**:
- ファイルは **コピー（cp）** であって **移動（mv）** ではない
- `.env` や `.claude/settings.local.json` がなければスキップ（エラーにしない）
- `gwq get` は patternが一意にマッチしないとfuzzy finderが起動するので、完全なブランチ名を渡す

### 6. 完了報告

以下を報告して終了：

- worktreeの絶対パス
- コピー結果（`.env`, `.claude/settings.local.json` をコピーしたか、なかったか）
- 配置した plan ファイルのパス

**cdはしない**。ユーザーは別ターミナルで `cd <path>` して作業を開始する。

## 注意点

- ユーザー確認が取れるまで `gwq add` を実行しない（CLAUDE.md のworktree関連ルールに準拠）
- ブランチ名prefix は `feat/` 固定ではない。作業内容から適切なものを選ぶ
- `gwq get` でfuzzy finderが起動しそうな場合（ブランチ名が他と衝突する等）は、`gwq list --json` からパスを抽出する方法にフォールバックする
