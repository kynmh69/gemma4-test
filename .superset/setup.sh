#!/usr/bin/env bash
set -euo pipefail

echo "Setting up workspace: ${SUPERSET_WORKSPACE_NAME:-unknown}"

if [[ -f "${SUPERSET_ROOT_PATH}/.env" ]]; then
  cp "${SUPERSET_ROOT_PATH}/.env" .env
  echo "Copied .env from root repository"
fi

if [[ -f package.json ]]; then
  if [[ -f bun.lockb ]] && command -v bun >/dev/null 2>&1; then
    bun install
  elif [[ -f pnpm-lock.yaml ]] && command -v pnpm >/dev/null 2>&1; then
    pnpm install
  elif [[ -f yarn.lock ]] && command -v yarn >/dev/null 2>&1; then
    yarn install
  elif command -v npm >/dev/null 2>&1; then
    npm install
  else
    echo "package.json found but no supported package manager is available"
    exit 1
  fi
fi

if [[ -f pyproject.toml ]] && command -v uv >/dev/null 2>&1; then
  uv sync
elif [[ -f requirements.txt ]] && command -v pip >/dev/null 2>&1; then
  pip install -r requirements.txt
fi

compose_file=""
for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if [[ -f "${candidate}" ]]; then
    compose_file="${candidate}"
    break
  fi
done

if [[ -n "${compose_file}" ]] && command -v docker >/dev/null 2>&1; then
  docker compose -f "${compose_file}" up -d
fi

echo "Setup complete"
