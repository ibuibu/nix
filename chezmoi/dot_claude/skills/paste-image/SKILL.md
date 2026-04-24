---
description: WSLでクリップボードの画像を /tmp/claude-clipboard/ にPNG保存してClaude Codeに読ませる。Windows側のPowerShell経由で取得する
---

# paste-image

WSL環境で、WindowsクリップボードにコピーされたスクリーンショットなどをPowerShell経由で取り出し、`/tmp/claude-clipboard/clipboard-<timestamp>.png` に保存してReadで読み込む。

Claude Code標準のCtrl+V画像ペーストはWSLで壊れている（BMP検知の不具合）ため、その代替として使う。

## 使うタイミング

- `/paste-image` で明示的に呼ばれたとき
- 「クリップボードの画像見て」「スクショ貼ったから見て」等の自然言語で依頼されたとき

## 前提

- WSL2上で動作していること（`uname -r` に `microsoft` を含む）
- Windows側で `powershell.exe` が PATH 経由で呼べること

## 実行手順

### 1. 画像を取得して保存

以下のBashコマンドを実行する。タイムスタンプ付きPNGを `/tmp/claude-clipboard/` に保存し、パスを標準出力に出す。

```bash
mkdir -p /tmp/claude-clipboard
TS=$(date +%Y%m%d-%H%M%S)
OUT="/tmp/claude-clipboard/clipboard-${TS}.png"
WIN_OUT=$(wslpath -w "$OUT")

powershell.exe -NoProfile -Command "
Add-Type -AssemblyName System.Windows.Forms;
Add-Type -AssemblyName System.Drawing;
\$img = [System.Windows.Forms.Clipboard]::GetImage();
if (-not \$img) { Write-Error 'clipboard has no image'; exit 1 };
\$img.Save('$WIN_OUT', [System.Drawing.Imaging.ImageFormat]::Png);
" && echo "SAVED: $OUT"
```

- `wslpath -w` でWSLパスをWindowsパス（例: `\\wsl.localhost\...\clipboard-...png`）に変換してPowerShellに渡す
- PowerShellの `\$` エスケープはbashヒアドキュメント経由でも動くようにしてある

### 2. 画像をRead

`SAVED:` 行に出力されたパスを Read ツールで読み込む。Claude Codeはマルチモーダルなので画像はそのまま解釈できる。

### 3. ユーザーの依頼に応える

画像の内容について説明したり、ユーザーが追加で指示した作業（「このUIを実装して」「このエラー読んで」等）を行う。

## 失敗時の対応

- `clipboard has no image` エラー: クリップボードに画像が無い。ユーザーにスクショ撮り直しを依頼
- `powershell.exe: command not found`: WSLでない可能性。`uname -r` を確認して報告
- 画像は取れたがReadで読めない: ファイルサイズを `ls -la` で確認

## 注意

- 保存先 `/tmp/claude-clipboard/` は再起動で消える。永続化したい場合はユーザーに別パスへのコピーを提案
- 同じタイムスタンプ（秒単位）で連続実行すると上書きされる。通常の操作では問題にならない
- macOS / ネイティブLinuxには未対応（将来 `pbpaste` / `xclip` 分岐を追加予定）
