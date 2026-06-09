# Ollama での起動手順

Gemma 4 は Homebrew で入れた [Ollama](https://ollama.com) 経由でインストール・実行する。  
Open WebUI だけ Docker で起動し、Ollama は **macOS ホスト上** で動かす（Metal 加速が効く）。

参考: [MacBook (16GB) でGemma 4をローカル実行してみた ─ Ollamaでモデル選定からUI構築、実プロジェクト活用まで](https://dev.classmethod.jp/articles/run-gemma4-locally-on-macbook-with-ollama/)

## モデル選定の目安

| モデル | 必要メモリ目安 | 16GB Mac |
|---|---|---|
| `gemma4:e2b` | 約 3–4 GB | 動作確認向き |
| `gemma4:e4b` | 約 5–6 GB | **推奨（スイートスポット）** |
| `gemma4:26b` | 約 18–19 GB | 非推奨（フリーズの可能性） |
| `gemma4:31b` | 20 GB 以上 | 非推奨 |

MoE の Active パラメータ数は計算量の話であり、**ロード時のメモリは全パラメータ分**必要になる点に注意。

## 手順

### 1. Ollama をインストール（Homebrew）

```bash
brew install ollama
```

### 2. Ollama サーバーを起動

```bash
ollama serve
```

バックグラウンド常駐にする場合:

```bash
brew services start ollama
```

別ターミナルで以降のコマンドを実行する。

### 3. モデルを pull

```bash
ollama pull gemma4:e4b
```

### 4. 推論確認（任意）

```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:e4b","prompt":"Say hello in one sentence.","stream":false}'
```

チャット形式で試す場合:

```bash
curl -s http://localhost:11434/api/chat \
  -d '{
    "model": "gemma4:e4b",
    "messages": [{"role": "user", "content": "日本の首都は？"}],
    "stream": false
  }'
```

### 5. Docker 実行環境を用意

Open WebUI 用に Docker が必要。Colima を使う例:

```bash
brew install colima docker docker-compose
colima start --runtime docker --memory 16
```

### 6. Open WebUI を起動

```bash
docker compose up -d --remove-orphans
```

ブラウザで http://localhost:3000 を開く。

Open WebUI から Ollama に接続できない場合は、接続 URL を次に設定する。

```text
http://host.docker.internal:11434
```

## 環境変数

| 変数 | デフォルト | 説明 |
|---|---|---|
| `POSTGRES_USER` | `openwebui` | PostgreSQL ユーザー |
| `POSTGRES_PASSWORD` | `openwebui` | PostgreSQL パスワード |
| `POSTGRES_DB` | `openwebui` | データベース名 |
| `GEMMA4_MODEL` | `gemma4:e4b` | Ollama モデル名 |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Open WebUI から見た Ollama URL |
| `OPEN_WEBUI_PORT` | `3000` | Web UI ポート |

## 停止

```bash
# Open WebUI
docker compose down --remove-orphans

# Ollama（brew services で起動した場合）
brew services stop ollama
```

## トラブルシュート

### UI にモデルが出ない

```bash
ollama list
curl http://localhost:11434/api/tags
```

- `ollama serve` が動いているか確認
- Open WebUI の Ollama 接続 URL が `http://host.docker.internal:11434` か確認

### Connection refused

Ollama が起動していない可能性がある。

```bash
brew services start ollama
# または
ollama serve
```

### 画面がフリーズする

モデルが大きすぎる可能性がある。16GB Mac では `gemma4:e4b` 以下を使う。

```bash
ollama rm gemma4:26b   # 不要モデルの削除例
ollama pull gemma4:e4b
```

### 初回だけ遅い

初回リクエストはモデルロードに 10 秒以上かかることがある。2 回目以降は速くなる。

### `llama-server binary not found`

`curl` や Open WebUI で推論すると次のエラーになる場合がある。

```text
error starting llama-server: llama-server binary not found
```

Homebrew の `ollama` 0.30.x では GGUF 用の `llama-server` が bottle に含まれていない。MLX モデルは動くが `gemma4:e4b` のような GGUF は失敗する。

```bash
curl -fsSL https://ollama.com/install.sh | sh

mkdir -p "$(brew --prefix ollama)/libexec/lib/ollama"
ln -sf /Applications/Ollama.app/Contents/Resources/llama-server \
  "$(brew --prefix ollama)/libexec/lib/ollama/llama-server"

brew services restart ollama
```

動作確認:

```bash
curl -s http://localhost:11434/api/generate \
  -d '{"model":"gemma4:e4b","prompt":"Say hello in one sentence.","stream":false}'
```

## 関連

- [README](../README.md)
- [compose.yml](../compose.yml)
- [Open WebUI - GitHub](https://github.com/open-webui/open-webui)
