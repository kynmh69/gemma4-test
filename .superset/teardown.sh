#!/usr/bin/env bash
set -euo pipefail

compose_file=""
for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if [[ -f "${candidate}" ]]; then
    compose_file="${candidate}"
    break
  fi
done

if [[ -n "${compose_file}" ]] && command -v docker >/dev/null 2>&1; then
  docker compose -f "${compose_file}" down
fi

echo "Teardown complete"
