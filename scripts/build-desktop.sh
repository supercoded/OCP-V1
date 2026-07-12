#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

npm run desktop:build
npm run dist --workspace=@ocp/desktop
