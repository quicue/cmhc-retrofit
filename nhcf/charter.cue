// NHCF Deep Retrofit Charter — constraint-first project planning
//
// Declares what "done" looks like for the NHCF deep energy retrofit
// program. The gap between these constraints and the current graph
// IS the remaining work.
//
// Usage:
//   cue eval ./nhcf/ -e nhcf_gaps
//   cue eval ./nhcf/ -e nhcf_milestone

package main

import "quicue.ca/charter@v0"

// ═══════════════════════════════════════════════════════════════════
// CHARTER — what the completed NHCF program looks like
// ═══════════════════════════════════════════════════════════════════

_nhcf_charter: charter.#Charter & {
	name: "NHCF Deep Retrofit — OCH Portfolio"

	scope: {
		total_resources: 18
		root:            "nhcf-agreement"

		required_resources: {
			"nhcf-agreement":        true
			"consultant-procurement": true
			"rideau-audit":          true
			"gladstone-audit":       true
			"bayshore-audit":        true
			"vanier-audit":          true
			"portfolio-baseline":    true
			"rideau-design":         true
			"gladstone-design":      true
			"bayshore-design":       true
			"vanier-design":         true
			"nhcf-design-review":    true
			"rideau-retrofit":       true
			"gladstone-retrofit":    true
			"bayshore-retrofit":     true
			"vanier-retrofit":       true
			"commissioning":         true
			"nhcf-closeout":         true
		}

		required_types: {
			Program:       true
			Assessment:    true
			Design:        true
			Milestone:     true
			Retrofit:      true
			Commissioning: true
			MV:            true
		}
	}

	gates: {
		"audits-complete": {
			phase:       2
			description: "All 4 building energy audits delivered with calibrated models"
			requires: {
				"rideau-audit":    true
				"gladstone-audit": true
				"bayshore-audit":  true
				"vanier-audit":    true
			}
		}

		"baseline-established": {
			phase:       3
			description: "Portfolio-wide EUI/GHG baseline confirms >=25% reduction achievable"
			requires: {
				"portfolio-baseline": true
			}
			depends_on: {
				"audits-complete": true
			}
		}

		"design-complete": {
			phase:       4
			description: "All retrofit designs approved + CMHC design milestone passed"
			requires: {
				"rideau-design":      true
				"gladstone-design":   true
				"bayshore-design":    true
				"vanier-design":      true
				"nhcf-design-review": true
			}
			depends_on: {
				"baseline-established": true
			}
		}

		"construction-complete": {
			phase:       6
			description: "All 4 buildings retrofitted"
			requires: {
				"rideau-retrofit":    true
				"gladstone-retrofit": true
				"bayshore-retrofit":  true
				"vanier-retrofit":    true
			}
			depends_on: {
				"design-complete": true
			}
		}

		"program-complete": {
			phase:       7
			description: "Commissioning done, 12-month M&V, NHCF compliance report filed"
			requires: {
				"commissioning": true
				"nhcf-closeout": true
			}
			depends_on: {
				"construction-complete": true
			}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════
// GAP ANALYSIS — what's missing from the current graph
// ═══════════════════════════════════════════════════════════════════

nhcf_gaps: charter.#GapAnalysis & {
	Charter: _nhcf_charter
	Graph:   program
}

// ═══════════════════════════════════════════════════════════════════
// MILESTONE — check a single gate
// ═══════════════════════════════════════════════════════════════════

_nhcf_milestone: charter.#Milestone & {
	Charter: _nhcf_charter
	Gate:    "design-complete"
	Graph:   program
}
nhcf_milestone: _nhcf_milestone.summary
