#!/bin/sh
# What the Go toolchain's own vetter makes of the submission.
#
# `go vet` and not a formatter: a patch the examiner proposes will not be
# gofmt-clean and refusing it for whitespace would spend a question on nothing.
# Vet reports the things that survive compilation and still do not work — a
# printf verb that does not match its argument, a lock copied by value, an
# unreachable branch.
#
# The mirror into /build is the same one compile.sh makes and for the same
# reason: vet type-checks, which means it builds, which means it writes.
set -eu

mkdir -p "${TMPDIR:-/build/tmp}"
W=/build/viva-lint
rm -rf "$W"
mkdir -p "$W"

cd /work
find . -name .git -prune -o -type f -print | while read -r f; do
  mkdir -p "$W/$(dirname "$f")"
  cp "$f" "$W/$f"
done
chmod -R u+w "$W"

cd "$W"
if [ ! -f go.mod ]; then
  cat > go.mod <<'MOD'
module viva

go 1.23
MOD
fi

go vet ./... 2>&1
