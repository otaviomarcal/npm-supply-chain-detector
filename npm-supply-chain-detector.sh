#!/usr/bin/env bash

# Compatibility entrypoint for the generalized repository name.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/shai-hulud-detector.sh" "$@"
