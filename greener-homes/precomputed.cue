// Pre-computed graph topology for the Greener Homes platform.
//
// Generated from the dependency DAG in platform.cue.
// Depth = max(depth of dependencies) + 1.
//
// Regenerate if platform.cue resources/edges change:
//   manually or via toposort.py

package main

platform: Precomputed: depth: {
	// Layer 0 — external data sources (roots)
	"cwec-weather":   0
	"nrcan-registry": 0
	"ieso-grid-data": 0

	// Layer 1 — data layer
	"audit-database":   1
	"h2k-filestore":    1
	"utility-datamart": 1

	// Layer 2 — compute layer
	"hot2000-engine": 2
	"rebate-engine":  2
	"backup-service": 2

	// Layer 3 — downstream compute
	"ers-calculator": 3
	"reporting-api":  3

	// Layer 4 — quality + analytics
	"qa-validator":     4
	"ghg-tracker":      4
	"homeowner-portal": 4

	// Layer 5 — presentation + ops
	"auditor-portal":    5
	"program-dashboard": 5
	monitoring:          5
}
