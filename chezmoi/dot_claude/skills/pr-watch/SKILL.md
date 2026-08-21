---
description: PR作成後にCI結果とレビューコメントの到着をバックグラウンドで待ち、並行してローカルでcodexレビューと敵対的検証を走らせる。CIが通ってレビューが揃った時点で resolve-reviews の相談フェーズに入り、push後は再度CIとレビューを待って未解決がなくなるまでラウンドを回す
---

# pr-watch

PR作成直後に起動する。CI待ちの空き時間にローカルレビューを回し切り、そのあと「CI + レビュー待ち → resolve-reviews → push」のラウンドを未解決がなくなるまで繰り返す。

## 1. 前提情報

```bash
gh pr view --json number,url,baseRefName
gh repo view --json owner,name
```

## 2. ローカルレビューを投入（最初にやる。ラウンド1のみ）

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

## 3. CI + レビュー到着待ち（ウォッチャー）

ラウンドごとに毎回ここに戻る。以下を1本の `run_in_background: true` の Bash で起動する。プロセス終了時にセッションが再開されるので、こちらからポーリングはしない。

`ROUND` はラウンド番号（1始まり）。`SHA` は **いま待ちたいコミット** で、スクリプト内で `git rev-parse HEAD` を取る。claude のレビューを `commit_id` で照合するため、push が完了してから起動する。

```bash
LOG=/tmp/pr-watch-<NUMBER>-r<ROUND>.log
: > "$LOG"
SHA=$(git rev-parse HEAD)
echo "sha=$SHA" >> "$LOG"

gh pr checks <NUMBER> --watch --fail-fast >> "$LOG" 2>&1
CI=$?
echo "ci_exit=$CI" >> "$LOG"
[ $CI -ne 0 ] && exit $CI

for _ in $(seq 1 30); do
  R=$(gh api --paginate repos/<OWNER>/<REPO>/pulls/<NUMBER>/reviews \
    --jq "[.[]|select(.user.login|ascii_downcase|test(\"claude\"))|select(.commit_id==\"$SHA\")]|length" \
    | awk '{s+=$1} END{print s+0}')
  if [ "$R" -gt 0 ]; then echo "claude_review=1" >> "$LOG"; break; fi
  sleep 30
done
grep -q claude_review "$LOG" || echo "claude_review=timeout" >> "$LOG"

Q='{repository(owner:"<OWNER>",name:"<REPO>"){pullRequest(number:<NUMBER>){reviewThreads(first:100){nodes{isResolved comments(first:1){nodes{author{login}}}}}}}}'
A=$(gh api graphql -f query="$Q" --jq '[.data.repository.pullRequest.reviewThreads.nodes[]|select(.isResolved==false)|.comments.nodes[0].author.login]|join(",")')
echo "unresolved_authors=$A" >> "$LOG"
```

claude のレビュー待ちは最大15分。`commit_id` で照合しているので、前ラウンドの古いレビューを新着と誤認しない。

## 4. 復帰後の分岐

`$LOG` を読んで判断する。

- `ci_exit` が 0 以外 → `gh run view --log-failed` で失敗原因を調査し、ユーザーに報告してループを止める。修正は勝手に始めず相談する
- `gh pr checks` がチェック未設定で失敗した場合 → CIなしと判断してレビュー待ちへ進む
- `claude_review=timeout` → 「CIは通ったが claude のレビューが15分以内に来なかった」と報告してループを終了する。待ち直しはユーザーが指示したときだけ
- `claude_review=1` かつ `unresolved_authors` が空 → 完了。ステップ7へ
- `claude_review=1` かつ `unresolved_authors` に `claude` を含む login がある（大文字小文字は区別しない。`claude[bot]` / `claude-code[bot]` などを想定）→ ユーザーに確認せずステップ5→6を続けて実行する
- `claude_review=1` かつ `unresolved_authors` が claude 以外だけ → ステップ5の統合報告を出したあと、resolve-reviews を起動してよいかユーザーに確認する

## 5. 統合報告（ラウンド1のみ）

ステップ2の4系統（codex review / codex adversarial-review / reviewer×2）の結果を突き合わせ、重複を1件にまとめて severity 順に報告する。

- 複数系統が同じ箇所を指摘したものは確度が高いものとして先頭に置く
- 1系統だけの指摘は、該当コードを自分で読んで裏を取る。裏が取れないものは落とす

ラウンド2以降はローカルレビューを回さないので、このステップは飛ばす。

## 6. resolve-reviews へ

`resolve-reviews` スキルに引き継ぐ。相談フェーズは resolve-reviews の手順どおり1件ずつ行い、ローカルレビュー由来の指摘も同じ流れで扱う。

resolve-reviews のステップ4（`git push`）まで完了したら、ステップ5（再レビュー依頼）は飛ばしてここに戻る。

## 7. ラウンドのループ

push が終わったらラウンド番号を1つ進めてステップ3へ戻る。ステップ2とステップ5は再実行しない。

終了条件:

- `unresolved_authors` が空になった → 「CI通過・未解決レビューなし」で完了報告して終わる
- ラウンド数が3に達した → それ以上回さず、残っている未解決スレッドを列挙して報告する
- CI失敗・レビュータイムアウト → ステップ4のとおり報告して止める
