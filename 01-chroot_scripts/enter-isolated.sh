#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/../chroot"

sudo unshare --fork --pid --mount bash -c "
  mount --make-rprivate /
  mount -t proc proc '$ROOT/proc'
  chroot '$ROOT' /bin/bash
"
