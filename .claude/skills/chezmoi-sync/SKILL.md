---
description: chezmoiで管理中のdotfilesについて、ホームとリポジトリの差分を1件ずつ確認し、方向（re-add / apply / skip）をユーザーと相談しながら解消する
---

# chezmoi-sync

`chezmoi status` で差分のあるファイルを列挙し、各ファイルの diff を見せた上でユーザーに方向を相談する。承認された方向だけをまとめて実行する。

## 使うタイミング

- `/chezmoi-sync` で明示的に呼ばれたとき
- 「chezmoi同期して」「dotfiles整理して」「ホームとrepoの差分見て」等で依頼されたとき

## 用語

- **re-add**: ホーム（`~/`）の内容をリポジトリ（source）に取り込む。ホーム側が正しいとき
- **apply**: リポジトリの内容をホームに適用する。repo側が正しいとき
- **skip**: 今回は触らない。ユーザーが次回以降も判断を保留したいときのみ選ぶ

**方針**: タイムスタンプや lock 系のような「自動更新されるだけ」のファイルも、skipせずに基本は re-add してコミットする。skipし続けると差分が残り続けて chezmoi status がノイジーになるだけなので、追跡対象にするか .gitignore で除外するかのどちらかに決める。

## 実行手順

### 1. 状態取得

```bash
chezmoi status
```

出力が空なら「差分なし」と報告して終了。

ステータス記号の読み方（2文字プレフィックス）:

- 1文字目 = source側（repo）の状態
- 2文字目 = target側（home）の状態
- `M` = 前回applyから変更あり、`A` = 追加、`D` = 削除、` ` = 変更なし

例: `MM .config/nvim/lazy-lock.json` は両方変更されている（要判断）。

### 2. ファイルごとに相談

差分ファイルを順に処理する。各ファイルについて:

1. `chezmoi diff <path>` で差分を表示（長い場合は要約）
2. ユーザーに AskUserQuestion で `re-add / apply / skip` を聞く
3. 推奨を添える（自動更新系タイムスタンプ/lock は基本 re-add 推奨、設定変更した認識のあるファイルは方向を明示）

**相談中は一切chezmoiコマンドを実行しない**。承認結果をメモリ上に溜める。

### 3. まとめて実行

全件の相談が終わったら、方向ごとにまとめて実行:

```bash
# re-addするファイル群
chezmoi re-add <path1> <path2> ...

# applyするファイル群
chezmoi apply <path1> <path2> ...
```

パスはホーム側絶対パス（例: `~/.config/nvim/init.lua`）を渡す。

### 4. 完了確認

```bash
chezmoi status
```

再度空になっていれば成功。まだ差分が残っていれば、skipしたものか新たに発生したものか報告する。

### 5. コミット提案

re-add によって `chezmoi/` 配下に変更が入った場合、`git status` でリポジトリ側の差分を確認し、ユーザーにコミット提案する（コミット自体は明示依頼があるまで実行しない）。

`.gitignore` に入っているファイル（例: `chezmoi/dot_claude/private_plugins/private_known_marketplaces.json`）は re-add しても git 追跡対象外なので、`chezmoi status` がクリアになれば完了で、git 側でコミットする物は無い。re-add 後に `git status` に出てこなくても慌てず、`git check-ignore` で確認する。

また、`chezmoi status` には出ないが `git status` に modified で出ているファイルもある（home と source が一致してるが、前回コミットから source 側だけ更新されたケース）。これは chezmoi-sync の範囲外だが、ついでにコミットに含めるか確認する。

## 注意

- `chezmoi apply` 全体は対話プロンプトが出る場合がある（`.claude/plugins/installed_plugins.json` のような自動更新ファイル）。必ず**パスを指定して**部分applyする
- 推測でre-add/applyを決めない。必ずユーザーに確認を取る
- ノイズ系ファイルも基本は re-add してコミットに含める方針。skipを選ぶのは例外。コミットしたくないなら `.gitignore` に追加する方向で提案する
