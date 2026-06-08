---
description: macOSでクリップボードの画像を /tmp/claude-clipboard/ にPNG保存してClaude Code/opencodeに読ませる。AppleScript (osascript) 経由で取得する
---

# paste-image

macOS環境で、クリップボードにコピーされたスクリーンショットなどをAppleScript経由で取り出し、`/tmp/claude-clipboard/clipboard-<timestamp>.png` に保存してReadで読み込む。

opencodeなど画像のCtrl+Vペーストに対応していないクライアントから使うことを想定。

## 使うタイミング

- `/paste-image` で明示的に呼ばれたとき
- 「クリップボードの画像見て」「スクショ貼ったから見て」等の自然言語で依頼されたとき

## 前提

- macOSで動作していること（`uname` が `Darwin`）
- `osascript` が使えること（標準で入っている）

## 実行手順

### 1. 画像を取得して保存

以下のBashコマンドを実行する。タイムスタンプ付きPNGを `/tmp/claude-clipboard/` に保存し、パスを標準出力に出す。

```bash
mkdir -p /tmp/claude-clipboard
TS=$(date +%Y%m%d-%H%M%S)
OUT="/tmp/claude-clipboard/clipboard-${TS}.png"

osascript <<EOF
set outFile to POSIX file "$OUT"
try
    set pngData to the clipboard as «class PNGf»
on error
    return "ERROR: clipboard has no image"
end try
set fp to open for access outFile with write permission
write pngData to fp
close access fp
return "OK"
EOF

[ -f "$OUT" ] && echo "SAVED: $OUT"
```

- `«class PNGf»` がAppleScriptでPNGクラスを表す特殊リテラル。`-e` ではエスケープしづらいのでヒアドキュメントで渡す
- クリップボードに画像が無い場合は `ERROR: clipboard has no image` を返す

### 2. 画像をRead

`SAVED:` 行に出力されたパスを Read ツールで読み込む。マルチモーダル対応のクライアント（Claude Code / opencode）はそのまま画像を解釈できる。

### 3. ユーザーの依頼に応える

画像の内容について説明したり、ユーザーが追加で指示した作業（「このUIを実装して」「このエラー読んで」等）を行う。

## 失敗時の対応

- `ERROR: clipboard has no image`: クリップボードに画像が無い。ユーザーにスクショ撮り直しを依頼（`Cmd+Shift+Ctrl+4` でクリップボードに直接コピー）
- `osascript: command not found`: macOS以外。`uname` を確認して報告
- 画像は取れたがReadで読めない: `ls -la` でファイルサイズを確認

## 注意

- 保存先 `/tmp/claude-clipboard/` は再起動で消える。永続化したい場合はユーザーに別パスへのコピーを提案
- 同じタイムスタンプ（秒単位）で連続実行すると上書きされる
- Linux / WSLには未対応
