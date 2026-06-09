# gemma4-test

[Docker Model Runner の `ai/gemma4`](https://hub.docker.com/r/ai/gemma4) と [Open WebUI](https://github.com/open-webui/open-webui) を組み合わせた、Gemma 4 のローカル動作確認環境。

## 構成

| サービス | イメージ | 役割 |
|---|---|---|
| `model-setup` | `docker:cli` | 起動時に `ai/gemma4` を pull |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | チャット UI（ポート 3000） |

Open WebUI は Docker Model Runner の Ollama 互換 API（`http://host.docker.internal:12434`）経由でモデルに接続する。

## 前提

- Docker Desktop（または Docker Engine + Docker Model Runner）
- Docker Compose v2
- Model Runner の TCP 有効化

```bash
docker desktop enable model-runner --tcp
```

## 起動

```bash
docker compose up -d
```

ブラウザで http://localhost:3000 を開き、モデル選択から `ai/gemma4:E4B`（または指定したタグ）を選ぶ。

## 停止・削除

```bash
# 停止
docker compose down

# データボリュームも削除
docker compose down -v
```

## 環境変数

`.env` に書くか、起動時に指定できる。

| 変数 | デフォルト | 説明 |
|---|---|---|
| `GEMMA4_MODEL` | `ai/gemma4:E4B` | 使用するモデルタグ |
| `OPEN_WEBUI_PORT` | `3000` | Web UI のホスト側ポート |
| `WEBUI_AUTH` | `false` | 認証の有効化 |
| `WEBUI_NAME` | `Gemma 4 Local Chat` | UI に表示する名前 |

### モデルタグ例

| タグ | 用途 |
|---|---|
| `ai/gemma4:E2B` | 最小。動作確認向き |
| `ai/gemma4:E4B` | デフォルト。バランス型 |
| `ai/gemma4:4B` / `ai/gemma4:4B-Q4_K_XL` | 4B 系 |
| `ai/gemma4:26B` / `ai/gemma4:31B` | 大規模（GPU メモリ要） |
| `ai/gemma4:latest` | 最新タグ |

例: 軽量モデルで起動

```bash
GEMMA4_MODEL=ai/gemma4:E2B docker compose up -d
```

## トラブルシュート

### モデルが UI に出てこない

```bash
# Model Runner が応答するか
curl http://localhost:12434/api/tags

# pull 済みモデル一覧
docker model list
```

### Connection refused

Model Runner の TCP が無効な可能性がある。

```bash
docker desktop enable model-runner --tcp
```

### 初回レスポンスが遅い

初回リクエストはモデルをメモリに載せるため時間がかかる。2 回目以降は速くなる。

## 参考リンク

- [ai/gemma4 - Docker Hub](https://hub.docker.com/r/ai/gemma4)
- [Open WebUI - GitHub](https://github.com/open-webui/open-webui)
- [Open WebUI integration - Docker Docs](https://docs.docker.com/ai/model-runner/openwebui-integration/)
