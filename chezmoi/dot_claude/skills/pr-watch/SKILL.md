---
description: PR作成後にCI結果とレビューコメントの到着をバックグラウンドで待ち、並行してローカルでcodexレビューと敵対的検証を走らせる。CIが通ってレビューが揃った時点で resolve-reviews の相談フェーズに入る
---

# pr-watch

PR作成直後に起動する。CI待ちの空き時間にローカルレビューを回し切ることが目的。

## 1. 前提情報

```bash
gh pr view --json number,url,baseRefName
gh repo view --json owner,name
```

## 2. ローカルレビューを投入（最初にやる）

CI待ちと並行させるため、ステップ3より前に必ず起動する。

codex companion のパス解決:

```bash
CODEX=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs | sort -V | tail -1)
```

以下を **それぞれ `run_in_background: true` の Bash** で起動する（規模判定はしない。常に走らせる）:

```bash
node "$CODEX" review --background --base <baseRefName> --scope branch
node "$CODEX" adversarial-review --background --base <baseRefName> --scope branch
```

同時に敵対的検証として `reviewer` サブエージェントを2体、Agent tool の `run_in_background: true` で起動する。2体は互いの結果を見ないこと。

- 1体目: `review-local` スキルの観点（バグ・セキュリティ・性能・テスト網羅）で `git diff <base>...HEAD` をレビュー
- 2体目: 実装内容ではなく採用した設計そのものを疑う。前提が崩れる条件、他の実装方針との比較、実運用で壊れる箇所を挙げる

## 3. CI + レビュー到着待ち

以下を1本の `run_in_background: true` の Bash で起動する。プロセス終了時にセッションが再開されるので、こちらからポーリングはしない。

```bash
LOG=/tmp/pr-watch-<NUMBER>.log
: > "$LOG"
gh pr checks <NUMBER> --watch --fail-fast >> "$LOG" 2>&1
CI=$?
echo "ci_exit=$CI" >> "$LOG"
[ $CI -ne 0 ] && exit $CI

Q='{repository(owner:"<OWNER>",name:"<REPO>"){pullRequest(number:<NUMBER>){reviewThreads(first:100){nodes{isResolved}}}}}'
for _ in $(seq 1 30); do
  C=$(gh api graphql -f query="$Q" --jq '[.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false)]|length')
  if [ "${C:-0}" -gt 0 ]; then echo "unresolved=$C" >> "$LOG"; exit 0; fi
  sleep 30
done
echo "unresolved=0 timeout" >> "$LOG"
```

レビュー待ちの上限は15分。botが何も言わない場合はタイムアウトで抜ける。

## 4. 復帰後の分岐

`$LOG` を読んで判断する。

- `ci_exit` が 0 以外 → `gh run view --log-failed` で失敗原因を調査し、ユーザーに報告する。修正は勝手に始めず相談する
- `gh pr checks` がチェック未設定で失敗した場合 → CIなしと判断してレビュー待ちへ進む
- `ci_exit=0` かつ `unresolved` が1件以上 → ステップ5へ
- `ci_exit=0` かつタイムアウト → ローカルレビュー結果だけ報告する

## 5. 統合報告

ステップ2の4系統（codex review / codex adversarial-review / reviewer×2）の結果を突き合わせ、重複を1件にまとめて severity 順に報告する。

- 複数系統が同じ箇所を指摘したものは確度が高いものとして先頭に置く
- 1系統だけの指摘は、該当コードを自分で読んで裏を取る。裏が取れないものは落とす

## 6. resolve-reviews へ

統合報告を出したあと `resolve-reviews` スキルに引き継ぐ。相談フェーズは resolve-reviews の手順どおり1件ずつ行い、ローカルレビュー由来の指摘も同じ流れで扱う。
