#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SCRIPT_DIR/../chroot"

BINS=(
  "/bin/bash"
  "/usr/bin/ps"
  "/usr/bin/ls"
)

copy_file_preserving_path() {
  local file="$1"

  sudo mkdir -p "$ROOT$(dirname "$file")"

  if [ ! -f "$ROOT$file" ]; then
    sudo cp "$file" "$ROOT$file"
  fi
}

copy_binary() {
  local bin="$1"

  copy_file_preserving_path "$bin"

  ldd "$bin" | awk '{print $3}' | grep '^/' | while read -r lib; do
    copy_file_preserving_path "$lib"
  done
}

sudo rm -rf "$ROOT"

sudo mkdir -p "$ROOT"
sudo mkdir -p "$ROOT/proc"
sudo mkdir -p "$ROOT/lib64"

for bin in "${BINS[@]}"; do
  copy_binary "$bin"
done

copy_file_preserving_path "/lib64/ld-linux-x86-64.so.2"

echo "Chroot criado em: $ROOT"
echo
echo "Entre com:"
echo "sudo chroot $ROOT /bin/bash"
