#!/usr/bin/env bash
set -eo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

# Stub nproc so this suite stays independent of the macOS cpu_count PR.
stub_bin=$(mktemp -d)
printf '%s\n' '#!/bin/sh' 'echo 2' > "$stub_bin/nproc"
chmod +x "$stub_bin/nproc"
export PATH="$stub_bin:$PATH"

# Fixture under a dotted parent dir so basename extension stripping is covered.
fixture=$(mktemp -d /tmp/psc.spaces.XXXXXX)
cleanup() {
  rm -rf "$fixture" "$stub_bin"
  rm -f "$root/found_files_total.txt" "$root/found.txt" "$root/delete_commands.sh"
}
trap cleanup EXIT

mkdir -p "$fixture/my photos/sub folder"
# Orphaned sidecar (no matching image)
touch "$fixture/my photos/sub folder/orphan file.xmp"
# Paired sidecar + image
touch "$fixture/my photos/sub folder/good photo.jpg"
touch "$fixture/my photos/sub folder/good photo.xmp"

rm -f found_files_total.txt found.txt delete_commands.sh
out=$(bash photo-sidecar-cleaner.sh "$fixture/my photos" xmp 2>&1) || {
  echo "$out" >&2
  echo "script failed" >&2
  exit 1
}

# Must not split the directory path at the space
if echo "$out" | grep -q 'No such file or directory'; then
  echo "$out" >&2
  echo "find still breaks on spaces" >&2
  exit 1
fi

grep -Fq "$fixture/my photos/sub folder/orphan file.xmp" found_files_total.txt
grep -Fq "$fixture/my photos/sub folder/good photo.xmp" found_files_total.txt

# Orphan should be scheduled for delete; paired image should appear in found.txt
grep -Fq "rm \"$fixture/my photos/sub folder/orphan file.xmp\"" delete_commands.sh
grep -Fq "$fixture/my photos/sub folder/good photo.jpg" found.txt

# Exclude dir with a space in its name
mkdir -p "$fixture/my photos/skip me"
touch "$fixture/my photos/skip me/ignored.xmp"
rm -f found_files_total.txt found.txt delete_commands.sh
bash photo-sidecar-cleaner.sh "$fixture/my photos" xmp "skip me" >/dev/null
if grep -Fq "skip me/ignored.xmp" found_files_total.txt 2>/dev/null; then
  echo "exclude dir with spaces was not pruned" >&2
  exit 1
fi
grep -Fq "$fixture/my photos/sub folder/orphan file.xmp" found_files_total.txt

echo "photo-sidecar-cleaner paths-with-spaces ok"
