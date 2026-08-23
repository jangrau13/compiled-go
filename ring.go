package ring

import "hash/crc32"

// Ring assigns each key to one of the nodes it was built with.
type Ring struct {
	nodes []string
}

func New(nodes []string) *Ring {
	return &Ring{nodes: nodes}
}

// Place hashes the key and takes it modulo the number of nodes, which spreads
// keys evenly across whatever nodes we currently have.
func (r *Ring) Place(key string) string {
	if len(r.nodes) == 0 {
		return ""
	}
	h := crc32.ChecksumIEEE([]byte(key))
	return r.nodes[int(h)%len(r.nodes)]
}

// Remove takes a node out of the ring. Keys on it must go somewhere; keys on
// the others should not move.
func (r *Ring) Remove(node string) {
	panic("not implemented")
}
