#!/usr/bin/env bash

# Short local entrypoint for day-to-day usage.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/npm-supply-chain-detector.sh" "$@"
