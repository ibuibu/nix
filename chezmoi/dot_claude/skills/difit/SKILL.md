---
description: カレントディレクトリで difit を起動し、差分レビュー用のURLを表示する
---

# difit

作業中のディレクトリで `difit` サーバーを起動し、レビュー用URLをユーザーに表示する。

## 使うタイミング

- `/difit` で明示的に呼ばれたとき
- 「difitで差分見せて」「差分レビューのURL出して」等の自然言語で依頼されたとき

## 実行手順

### 1. 実行ディレクトリを決める

カレントディレクトリで実行する。会話の流れで別ディレクトリへ移動している場合は、その移動先で実行する。

### 2. 起動

```bash
difit working --include-untracked --background
```

`--background` を付けるとサーバーを常駐させたままコマンドが即座に終了するため、Bash ツールの `run_in_background` は不要。

リビジョン指定の依頼があれば `working` を置き換える（例: `difit HEAD~1 --background`）。

### 3. URLを表示

出力は次の形式のJSON1行。

```json
{"port":4966,"url":"http://localhost:4966","pid":12345}
```

`url` と `pid` をユーザーに伝える。停止したいときは `kill <pid>`。

## 注意

- ポートが使用中の場合は自動で別ポートに割り当てられるため、URLは必ず出力JSONから読む。
- `--include-untracked` は untracked ファイルに `git add --intent-to-add` を実行する。取り消しは `git reset -- <ファイル>`。
