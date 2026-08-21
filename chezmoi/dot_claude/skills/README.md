# PRレビューループ

PR作成からレビュー全解決までを、フックとスキルの連携で自動的に回す仕組み。関係するファイルは以下の3つ。

| ファイル | 役割 |
| --- | --- |
| `dot_claude/settings.json.tmpl` | PostToolUse フックで `gh pr create` を検知し、pr-watch の起動を指示する |
| `dot_claude/skills/pr-watch/SKILL.md` | ループの親。CI待ち・ローカルレビュー・ラウンド制御 |
| `dot_claude/skills/resolve-reviews/SKILL.md` | ループの1周分。レビューコメントを1件ずつ相談して対応・push |

## 全体の流れ

```
gh pr create
  └─ PostToolUse フックが /pull/ を含む出力を検知 → pr-watch 起動を additionalContext で指示

pr-watch
  ├─ [ラウンド1のみ] ローカルレビューを4系統バックグラウンド起動
  │    codex review / codex adversarial-review / reviewer サブエージェント×2
  │
  ├─ ウォッチャー（background bash 1本）
  │    1. SHA=$(git rev-parse HEAD) を記録
  │    2. gh pr checks --watch --fail-fast で CI を待つ
  │    3. claude のレビューを commit_id == SHA で照合しながら最大15分待つ
  │    4. 未解決スレッドの著者 login を1回取得
  │    → プロセス終了でセッションが自動復帰する
  │
  ├─ ログを読んで分岐
  │    CI失敗 / レビュータイムアウト → 報告して停止
  │    未解決なし                    → 完了して終了
  │    claude の指摘あり             → 確認なしで resolve-reviews へ
  │    claude 以外だけ              → ユーザーに確認してから resolve-reviews へ
  │
  ├─ [ラウンド1のみ] ローカルレビュー4系統の統合報告
  │
  └─ resolve-reviews（1件ずつ相談 → 対応 → resolve → push）
       └─ push完了後、ラウンド番号を進めてウォッチャーへ戻る
```

## 設計上のポイント

### 起動時にユーザーへ確認しない

フックの `additionalContext` と pr-watch 冒頭の両方に「確認せず即座に起動する」と明記している。片方だけだと質問に降格させる挙動が混ざるため、両方に書く。判断を仰ぐのは CI 失敗時と、claude 以外のレビュアーだけが未解決で残っている場合のみ。

### ポーリングを自前ループで書かない

CI待ちとレビュー待ちは `run_in_background: true` の Bash 1本にまとめる。プロセスが終了するとセッションが自動で再開されるため、エージェント側から状態を問い合わせる必要がない。待ち時間にトークンを消費しない。

### 新着レビューの判定に commit_id を使う

`reviewThreads` だけを見ると前ラウンドの古いスレッドと区別できない。ウォッチャー起動時の HEAD を記録し、`gh api repos/{owner}/{repo}/pulls/{number}/reviews` の `commit_id` と一致する claude のレビューだけを新着とみなす。このため、ウォッチャーは push が完了してから起動する。

### ラウンド1だけの処理

ローカルレビュー（4系統の起動）と統合報告はラウンド1限定。2周目以降は claude のレビュー対応に絞る。

### 終了条件

| 状態 | 挙動 |
| --- | --- |
| 未解決スレッドが空 | 完了報告して終了 |
| claude の指摘あり | 確認なしで次ラウンドへ自動継続 |
| ラウンド3到達 | 残りの未解決スレッドを列挙して停止 |
| CI失敗 | `gh run view --log-failed` で調査し、報告して停止 |
| claude のレビューが15分来ない | 報告して終了。待ち直しはユーザーの指示があるときだけ |

ラウンド上限3は暴走防止のための固定値。

### resolve-reviews 単体起動との違い

pr-watch から呼ぶ場合は、resolve-reviews のステップ5（再レビュー依頼）を飛ばして pr-watch に戻る。ウォッチャーが再レビューの到着を待つ役割を担うため。単体で起動したときは従来どおりステップ5まで実行する。

## 既知の制約

claude が指摘なしのときに inline スレッドを作らず summary review だけ返す場合は、未解決スレッドが空になり正常に完了扱いになる。一方、claude が review ではなく PR の issue comment で結果を返す設定になっていると `reviews` API に載らないため、ウォッチャーは15分でタイムアウトする。
