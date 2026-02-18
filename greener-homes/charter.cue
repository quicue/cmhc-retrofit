// Greener Homes Platform Charter — constraint-first infrastructure readiness
//
// Declares what a fully operational Greener Homes platform looks like.
// Unlike NHCF (project delivery phases), this charter defines capability
// gates for service topology — each gate represents a platform layer
// that must be operational before the next can function.
//
// Usage:
//   cue eval ./greener-homes/ -e gh_gaps
//   cue eval ./greener-homes/ -e gh_milestone

package main

import "quicue.ca/charter@v0"

// ═══════════════════════════════════════════════════════════════════
// CHARTER — what a fully operational platform looks like
// ═══════════════════════════════════════════════════════════════════

_gh_charter: charter.#Charter & {
	name: "Greener Homes — Ontario Regional Processing Platform"

	scope: {
		total_resources: 17
		root: {
			"cwec-weather":   true
			"nrcan-registry": true
			"ieso-grid-data": true
		}

		required_resources: {
			"cwec-weather":       true
			"nrcan-registry":     true
			"ieso-grid-data":     true
			"audit-database":     true
			"h2k-filestore":      true
			"utility-datamart":   true
			"hot2000-engine":     true
			"ers-calculator":     true
			"rebate-engine":      true
			"qa-validator":       true
			"ghg-tracker":        true
			"reporting-api":      true
			"auditor-portal":     true
			"program-dashboard":  true
			"homeowner-portal":   true
			"backup-service":     true
			monitoring:           true
		}

		required_types: {
			DataSource:       true
			Database:         true
			Storage:          true
			Compute:          true
			QualityAssurance: true
			Analytics:        true
			API:              true
			WebApp:           true
			Operations:       true
		}

		min_depth: 5 // 6 layers = depth indices 0-5
	}

	gates: {
		"data-sources-online": {
			phase:       0
			description: "All 3 external data sources reachable (CWEC weather, NRCan registry, IESO grid)"
			requires: {
				"cwec-weather":   true
				"nrcan-registry": true
				"ieso-grid-data": true
			}
		}

		"storage-ready": {
			phase:       1
			description: "Databases and filestore operational — audit records, .h2k files, utility data"
			requires: {
				"audit-database":   true
				"h2k-filestore":    true
				"utility-datamart": true
			}
			depends_on: {
				"data-sources-online": true
			}
		}

		"compute-online": {
			phase:       2
			description: "Simulation and calculation engines running — HOT2000, ERS, rebate"
			requires: {
				"hot2000-engine": true
				"ers-calculator": true
				"rebate-engine":  true
			}
			depends_on: {
				"storage-ready": true
			}
		}

		"quality-active": {
			phase:       3
			description: "QA validation and GHG tracking operational"
			requires: {
				"qa-validator": true
				"ghg-tracker":  true
				"reporting-api": true
			}
			depends_on: {
				"compute-online": true
			}
		}

		"platform-live": {
			phase:       4
			description: "All portals accessible — auditors, program managers, homeowners"
			requires: {
				"auditor-portal":    true
				"program-dashboard": true
				"homeowner-portal":  true
				"backup-service":    true
				monitoring:          true
			}
			depends_on: {
				"quality-active": true
			}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════
// GAP ANALYSIS — what's missing from the current platform graph
// ═══════════════════════════════════════════════════════════════════

gh_gaps: charter.#GapAnalysis & {
	Charter: _gh_charter
	Graph:   platform
}

// ═══════════════════════════════════════════════════════════════════
// MILESTONE — check a single capability gate
// ═══════════════════════════════════════════════════════════════════

_gh_milestone: charter.#Milestone & {
	Charter: _gh_charter
	Gate:    "compute-online"
	Graph:   platform
}
gh_milestone: _gh_milestone.summary
