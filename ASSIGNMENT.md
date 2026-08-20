# Place the keys (example assignment)

Four storage nodes, and every key has to live on exactly one of them. When a
node is removed its keys must go somewhere — and the keys on the *other* nodes
should stay where they are, because moving a key means copying it across the
network.

Your problem is `ring.go`, and two methods in it.

## What to do

1. **`Place(key)`** — return the node this key belongs on.
2. **`Remove(node)`** — take a node out. Keys on it go elsewhere; keys on the
   others should not move.

## What you are marked on

Whether you can explain, in a viva, what your code actually does. The examiner
can run your ring against cases you have not seen, so a prediction you make
about its behaviour will be checked against the behaviour.
