---
name: skill-creator
description: 新しいClaude Skillの設計と雛形作成を対話で支援。要件整理からSKILL.md作成、構成決定、最終チェックまでを一貫して進めるときに使う。
---

# skill-creator

Claude Skill を新規作成するときに使う。
要件整理から `SKILL.md` 作成、必要なディレクトリ作成、最終チェックまでを行う。

## 使うタイミング

- ユーザーが「Skillを作りたい」「SKILL.mdを書きたい」と依頼したとき
- 既存Skillを参考に、新しいSkillを最小構成で追加したいとき
- Skillの設計方針（description、構成、運用手順）を整理したいとき

## 実行方針

1. 要件を短く確定する
2. Skillのディレクトリ構成を決める
3. `SKILL.md` を作成する
4. 必要なら `scripts/` `references/` `assets/` を追加する
5. 最終チェックをして利用方法を案内する

## 1) 要件ヒアリング

次の観点を最初に確認する。

- Skill名（kebab-case 推奨）
- 何を自動化するSkillか
- 想定トリガー（どういう依頼文で発動させたいか）
- 実行時に使うツール（bash/read/edit など）
- 出力物（コード、ドキュメント、レビュー結果など）

ユーザーへの確認は短く行い、クローズドクエスチョンは AskUserQuestion を使う。

## 2) ディレクトリ構成

まず最小構成で作る。

```text
<skill-name>/
└── SKILL.md
```

必要になったら追加する。

```text
<skill-name>/
├── SKILL.md
├── scripts/      # 実行スクリプト
├── references/   # 参照資料
└── assets/       # テンプレート/静的ファイル
```

## 3) SKILL.md の書き方

フロントマターは少なく保つ。

```yaml
---
description: このSkillが何を支援するかを簡潔に書く
---
```

本文は「いつ使うか」「どう進めるか」を命令形で書く。

- 目的
- 使うタイミング
- 手順（番号付き）
- 注意点（安全性、除外条件）
- 完了条件

description は発動判定に効くため、具体的な語彙を含める。

## 4) Progressive Disclosure

初期ロード情報を最小化し、必要時のみ追加情報を読む。

- 長い仕様は `references/` に分離
- 実行ロジックは `scripts/` へ分離
- `SKILL.md` は判断基準と手順に集中

## 5) 仕上げチェック

- `SKILL.md` が存在する
- description が曖昧すぎない
- 手順が3-7ステップで明確
- 危険操作時の確認ルールがある
- 実行後の完了条件がある

## 6) 作成時のデフォルト

迷った場合は次をデフォルトにする。

- Skill配置先: `chezmoi/dot_config/opencode/skills/<skill-name>/`
- 構成: 最小構成（`SKILL.md` のみ）
- 文体: 短く、命令形、冗長説明なし

## 7) 出力テンプレート

新規作成時は、最終的に以下をユーザーへ返す。

1. 作成したファイル一覧
2. `SKILL.md` の要点（description/用途/手順）
3. 発動例（1-2個）

発動例:

- 「skill-creatorを使ってレビュー補助Skillを作って」
- 「新しいSkillを追加したい。skill-creatorで最小構成から始める」
