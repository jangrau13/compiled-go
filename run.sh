#!/bin/sh
# What the examiner may run against the candidate's ring.
#
# Each target is a `main` written here and compiled beside the candidate's own
# source. /work is read-only and `go build` writes, so the package is assembled
# in /build — the one path that is both writable and executable.
#
# These report what the submission did rather than marking it: a spread that
# piles every key on one node is a number to ask about, not a failure. A
# non-zero exit means the code did not run at all.
#
# Usage: run.sh [--list | <target>]
set -eu

TARGET="${1:---default}"

if [ "$TARGET" = "--list" ]; then
  printf '%s\t%s\n' \
    place 'Places five keys on a three-node ring and prints where each landed. Start here: it says whether there is anything to examine.' \
    spread 'Places 10000 keys on four nodes and prints how many landed on each. Shows whether the ring spreads keys or piles them on one node.' \
    removal 'Removes one node of four and counts how many of 10000 keys moved, separating those that had to move from those that moved for no reason.' \
    determinism 'Builds the same four-node ring twice and counts the keys the two rings disagree about. Placement that depends on map order or a fresh seed shows up here.'
  exit 0
fi

[ "$TARGET" = "--default" ] && TARGET=place

# $TMPDIR is set to /build/tmp by the image; the tmpfs is mounted fresh for each
# session, so the directory itself has to be made here rather than baked in.
mkdir -p "${TMPDIR:-/build/tmp}"

# A directory of this script's own: the assignment's scenarios build in
# /build/run, and a run must not tread on one that is still going.
W=/build/viva-run
rm -rf "$W"
mkdir -p "$W"

[ -f /work/ring.go ] || { echo "the submission has no ring.go at its root"; exit 2; }

# Everything the package is made of, not ring.go alone: a candidate may have put
# the hashing in a second file beside it. A root `package main` is left where it
# is — the target's own main is written below, and two would not compile
# together.
for f in /work/*.go; do
  [ -f "$f" ] || continue
  case "$f" in *_test.go) continue ;; esac
  if grep -q '^package main$' "$f"; then continue; fi
  cp "$f" "$W/"
done

# The checkout can be mounted without write permission, and the package clause
# is rewritten below.
chmod u+w "$W"/*.go

cd "$W"
cat > go.mod <<'MOD'
module viva

go 1.23
MOD

# The candidate's files declare a library package; the target declares `package
# main`. Rewriting the one clause is what lets both live in one directory
# without asking the candidate to lay their repository out our way.
sed -i 's/^package [A-Za-z_][A-Za-z0-9_]*$/package main/' *.go

case "$TARGET" in
place)
  cat > viva_main.go <<'GO'
package main

import "fmt"

// The submission's own ring, placing a handful of keys on three nodes. The
// first thing to run: it says whether there is a working ring to ask about.
func main() {
	r := New([]string{"alpha", "beta", "gamma"})
	fmt.Println("ring over alpha, beta, gamma:")
	for _, k := range []string{"user-1", "user-2", "session-9", "cart-42", "order-7"} {
		fmt.Printf("  %-10s -> %s\n", k, r.Place(k))
	}
}
GO
  ;;
spread)
  cat > viva_main.go <<'GO'
package main

import "fmt"

// How evenly 10,000 keys land across four nodes. A ring that hashes the node
// name once puts most keys on whichever node happens to sit after the others.
func main() {
	nodes := []string{"a", "b", "c", "d"}
	r := New(nodes)
	count := map[string]int{}
	for i := 0; i < 10000; i++ {
		count[r.Place(fmt.Sprintf("key-%d", i))]++
	}
	fmt.Println("10000 keys across 4 nodes:")
	for _, n := range nodes {
		fmt.Printf("  %s  %d\n", n, count[n])
	}
}
GO
  ;;
removal)
  cat > viva_main.go <<'GO'
package main

import "fmt"

// How many keys move when one node of four is removed. A correct ring moves
// roughly the quarter that lived on the departed node and nothing else;
// hash % len(nodes) moves almost everything.
func main() {
	nodes := []string{"a", "b", "c", "d"}
	keys := make([]string, 10000)
	for i := range keys {
		keys[i] = fmt.Sprintf("key-%d", i)
	}

	before := New(nodes)
	was := make(map[string]string, len(keys))
	for _, k := range keys {
		was[k] = before.Place(k)
	}

	after := New(nodes)
	after.Remove("c")

	moved, movedOffC := 0, 0
	for _, k := range keys {
		if after.Place(k) != was[k] {
			moved++
			if was[k] == "c" {
				movedOffC++
			}
		}
	}
	fmt.Printf("removed node c of 4\n")
	fmt.Printf("  keys that moved:               %d of %d\n", moved, len(keys))
	fmt.Printf("  of those, keys that were on c: %d\n", movedOffC)
	fmt.Printf("  keys that moved for no reason: %d\n", moved-movedOffC)
}
GO
  ;;
determinism)
  cat > viva_main.go <<'GO'
package main

import "fmt"

// Two rings built from the same nodes have to place every key the same way:
// the node holding a key is a fact every caller has to agree on, and one
// process cannot ask another where it put things. A ring that picks by ranging
// over a map, or that seeds itself from anything that varies, disagrees with
// its own twin.
func main() {
	nodes := []string{"a", "b", "c", "d"}
	first := New(nodes)
	second := New(nodes)

	differed := 0
	var example string
	for i := 0; i < 10000; i++ {
		key := fmt.Sprintf("key-%d", i)
		a, b := first.Place(key), second.Place(key)
		if a != b {
			if differed == 0 {
				example = fmt.Sprintf("%s -> %s in one ring, %s in the other", key, a, b)
			}
			differed++
		}
	}

	fmt.Println("two rings over the same 4 nodes, 10000 keys:")
	fmt.Printf("  keys the two rings disagree about: %d\n", differed)
	if differed > 0 {
		fmt.Printf("  first disagreement: %s\n", example)
		fmt.Println("\nPLACEMENT IS NOT STABLE ACROSS TWO IDENTICAL RINGS")
	}
}
GO
  ;;
*)
  echo "no such target: $TARGET"
  exit 2
  ;;
esac

go run . 2>&1
