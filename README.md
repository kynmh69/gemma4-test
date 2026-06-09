# gemma4-test

Homebrew で入れた [Ollama](https://ollama.com) の `gemma4` と [Open WebUI](https://github.com/open-webui/open-webui) を組み合わせた、Gemma 4 のローカル動作確認環境。

## 構成

| コンポーネント | インストール | 役割 |
|---|---|---|
| Ollama | `brew install ollama`（ホスト） | Gemma 4 の pull / 推論 API（`:11434`） |
| PostgreSQL | `docker compose up -d` | Open WebUI 本体の DB（ユーザー・チャット履歴など） |
| `open-webui` | `docker compose up -d` | チャット UI（ポート 3000） |

Ollama は **macOS ホスト上** で動かす。Metal 加速が効く。Open WebUI だけ Docker で起動する。

## 前提

- Homebrew
- Docker + Docker Compose v2（Open WebUI 用）
- 16GB Mac では `gemma4:e4b` 推奨

## セットアップ

### 1. Ollama をインストール

```bash
brew install ollama
```

### 2. Ollama を起動

```bash
ollama serve
```

別ターミナルで以降を実行する。macOS では `brew services start ollama` でもよい。

### 3. モデルを pull

```bash
ollama pull gemma4:e4b
```

### 4. 環境変数を用意（任意）

PostgreSQL のパスワードなどを変えたい場合:

```bash
cp .env.example .env
# .env の POSTGRES_PASSWORD を編集
```

未設定の場合は compose 内のデフォルト（`openwebui` / `openwebui`）が使われる。

### 5. Open WebUI を起動

```bash
docker compose up -d --remove-orphans
```

http://localhost:3000 を開き、モデル `gemma4:e4b` を選ぶ。

初回起動時、Open WebUI が PostgreSQL にテーブルを自動作成する。

詳細は [Ollama での起動手順](docs/ollama-setup.md) を参照。

## 停止・削除

```bash
# Open WebUI のみ停止（旧 compose のコンテナもまとめて削除）
docker compose down --remove-orphans

# データボリュームも削除（PostgreSQL のチャット履歴も消える）
docker compose down -v --remove-orphans
```

Ollama は別プロセスのため、必要なら `brew services stop ollama` などで停止する。

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `POSTGRES_USER` | `openwebui` | PostgreSQL ユーザー |
| `POSTGRES_PASSWORD` | `openwebui` | PostgreSQL パスワード（本番では必ず変更） |
| `POSTGRES_DB` | `openwebui` | データベース名 |
| `GEMMA4_MODEL` | `gemma4:e4b` | Ollama モデル名 |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Open WebUI から見た Ollama URL |
| `OPEN_WEBUI_PORT` | `3000` | Web UI のホスト側ポート |
| `WEBUI_AUTH` | `false` | 認証の有効化 |
| `WEBUI_NAME` | `Gemma 4 Local Chat` | UI 表示名 |

### モデル例

| モデル | 用途 |
|---|---|
| `gemma4:e2b` | 最小。動作確認向き |
| `gemma4:e4b` | デフォルト。16GB Mac 向け |
| `gemma4:26b` | 大規模（16GB Mac では非推奨） |

## ドキュメント

- [Ollama での起動手順](docs/ollama-setup.md) — brew インストール、モデル選定、Colima 連携、トラブルシュート

## SQLite から PostgreSQL へ移行

以前 SQLite（`open-webui` ボリューム内の `webui.db`）で運用していた場合、**自動移行はない**。既存のチャット履歴を残すには [pgloader](https://github.com/dimitri/pgloader) などで手動移行が必要。新規セットアップならそのまま `docker compose up` でよい。

## トラブルシュート

### Open WebUI が PostgreSQL に接続できない

```bash
docker compose ps
docker compose logs postgres open-webui
```

`postgres` が `healthy` になるまで Open WebUI は起動を待つ。パスワードを `.env` で変えた場合は、`DATABASE_URL` と `POSTGRES_*` が一致しているか確認する。

### モデルが UI に出てこない

```bash
ollama list
curl http://localhost:11434/api/tags
```

Open WebUI の Ollama 接続 URL を `http://host.docker.internal:11434` に設定する。

### `llama-server binary not found`（Homebrew 版 Ollama 0.30.x）

Ollama 0.30 以降、GGUF モデル（`gemma4:e4b` など）は `llama-server` が必要だが、Homebrew の bottle には同梱されていない。

**対処（推奨）:** 公式アプリを入れて `llama-server` をリンクする。

```bash
# 公式 Ollama をインストール（/Applications/Ollama.app）
curl -fsSL https://ollama.com/install.sh | sh

# Homebrew 版が探すパスへ llama-server をリンク
mkdir -p "$(brew --prefix ollama)/libexec/lib/ollama"
ln -sf /Applications/Ollama.app/Contents/Resources/llama-server \
  "$(brew --prefix ollama)/libexec/lib/ollama/llama-server"

brew services restart ollama
```

`brew upgrade ollama` のたびにリンクの再作成が必要になる場合がある。恒久対応は [Homebrew の修正 PR](https://github.com/Homebrew/homebrew-core/pull/285963) のマージ待ち、または公式アプリのみで運用（`brew uninstall ollama` 後に `/Applications/Ollama.app` を使う）。

### 推論で画面がフリーズする

モデルが大きすぎる可能性がある。16GB Mac では `gemma4:e4b` を使う。

## 参考リンク

- [MacBook (16GB) でGemma 4をローカル実行してみた（DevelopersIO）](https://dev.classmethod.jp/articles/run-gemma4-locally-on-macbook-with-ollama/)
- [Ollama](https://ollama.com)
- [Open WebUI - GitHub](https://github.com/open-webui/open-webui)
