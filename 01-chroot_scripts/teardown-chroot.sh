#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/../chroot"

if mountpoint -q "$ROOT/proc"; then
  sudo umount "$ROOT/proc"
fi

sudo rm -rf "$ROOT"

echo "Chroot desmontado/removido de: $ROOT"
