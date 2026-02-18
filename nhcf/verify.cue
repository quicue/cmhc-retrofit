// Contract — graph invariants that must unify with computed output
//
// These constraints participate in evaluation. If the graph changes
// in a way that violates them, cue vet rejects the whole package.
// The knowledge and the data are the same thing.

package main

// ─── Structure ─────────────────────────────────────────────────
// The graph must validate. No dangling deps, no cycles.
validate: valid: true

// ─── Roots ─────────────────────────────────────────────────────
// The NHCF agreement is the sole program root — everything flows from it.
program: roots: {"nhcf-agreement": true}

// ─── Scale ─────────────────────────────────────────────────────
// 18 work packages, 8 phases. If these change, the contract breaks
// and forces you to update the knowledge intentionally.
summary: {
	total_work_packages: 18
	schedule_phases:     8
	graph_valid:         true
}
