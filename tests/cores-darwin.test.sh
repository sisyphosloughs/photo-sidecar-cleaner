#!/usr/bin/env bash
set -eo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)

set +e
nproc >/tmp/psc-nproc.out 2>/tmp/psc-nproc.err
red=$?
set -e
if [ "$red" -eq 0 ]; then
  echo "nproc unexpectedly succeeded" >&2
  exit 1
fi
grep -q "command not found" /tmp/psc-nproc.err

# shellcheck disable=SC1091
source "$root/photo-sidecar-cleaner.sh"
got=$(cpu_count)
want=$(sysctl -n hw.ncpu)
[ "$got" = "$want" ]
echo "photo-sidecar-cleaner darwin ok (nproc exit $red, cores $got)"
