#!/bin/sh
# Does the submission build?
#
# This is the gate that decides whether the examiner may propose a patch at
# all, so the exit code has to be the compiler's and nothing else's: a check
# that is stricter than `go build` would refuse patches that are fine, and one
# that is looser would let a patch through to fail inside a run, where the
# examiner cannot tell its own edit from the candidate's code.
#
# /work is read-only to a toolchain's way of thinking — go writes a build cache
# and, given a module, a go.sum — so the checkout is mirrored into /build and
# built there.
set -eu

mkdir -p "${TMPDIR:-/build/tmp}"
W=/build/viva-compile
rm -rf "$W"
mkdir -p "$W"

# File by file rather than `cp -R`, so the copy's directories get this process's
# own permissions: a checkout mounted read-only would otherwise be reproduced as
# directories nothing may write into.
cd /work
find . -name .git -prune -o -type f -print | while read -r f; do
  mkdir -p "$W/$(dirname "$f")"
  cp "$f" "$W/$f"
done
chmod -R u+w "$W"

cd "$W"
# An assignment of one file at the repository root needs no module for the
# candidate to have finished it. Supplying one only where none was shipped keeps
# a missing go.mod from being reported as a compile error, and leaves a
# candidate who did ship one building under their own.
if [ ! -f go.mod ]; then
  cat > go.mod <<'MOD'
module viva

go 1.23
MOD
fi

go build ./... 2>&1
