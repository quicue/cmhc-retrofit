// Contract — graph invariants that must unify with computed output

package main

// ─── Structure ─────────────────────────────────────────────────
validate: valid: true

// ─── Roots ─────────────────────────────────────────────────────
// Three external data sources are the platform foundation.
platform: roots: {
	"cwec-weather":   true
	"nrcan-registry": true
	"ieso-grid-data": true
}

// ─── Scale ─────────────────────────────────────────────────────
summary: {
	total_services:      17
	foundation_services: 3
	service_layers:      6
	graph_valid:         true
}
