// Package ring places keys on a fixed set of nodes.
//
// The plumbing is settled: what a node is, how keys arrive, and what the
// caller does with the answer. Place is the part with a decision in it.
package ring

// Ring assigns each key to one of the nodes it was built with.
type Ring struct {
	nodes []string
}

func New(nodes []string) *Ring {
	return &Ring{nodes: nodes}
}

// Place returns the node this key belongs on.
func (r *Ring) Place(key string) string {
	panic("not implemented")
}

// Remove takes a node out of the ring. Keys on it must go somewhere; keys on
// the others should not move.
func (r *Ring) Remove(node string) {
	panic("not implemented")
}
