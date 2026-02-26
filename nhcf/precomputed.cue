// Pre-computed graph topology for the NHCF deep retrofit portfolio.
//
// Generated from the dependency DAG in portfolio.cue.
// Depth = max(depth of dependencies) + 1.
//
// Regenerate if portfolio.cue work packages/edges change.

package main

program: Precomputed: depth: {
	// Phase 0 — program initiation
	"nhcf-agreement": 0

	// Phase 1 — procurement
	"consultant-procurement": 1

	// Phase 2 — site audits
	"rideau-audit":    2
	"gladstone-audit": 2
	"bayshore-audit":  2
	"vanier-audit":    2

	// Phase 3 — design + baseline
	"portfolio-baseline": 3
	"rideau-design":      3
	"gladstone-design":   3
	"bayshore-design":    3
	"vanier-design":      3

	// Phase 4 — design review gate
	"nhcf-design-review": 4

	// Phase 5 — retrofit execution
	"rideau-retrofit":    5
	"gladstone-retrofit": 5
	"bayshore-retrofit":  5
	"vanier-retrofit":    5

	// Phase 6 — commissioning
	commissioning: 6

	// Phase 7 — closeout
	"nhcf-closeout": 7
}
