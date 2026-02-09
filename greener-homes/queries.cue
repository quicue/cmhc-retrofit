// Analysis Queries — Platform operations questions
//
// Each expression answers a question from the team operating the
// Greener Homes technical platform. Different questions than the NHCF
// scenario — infrastructure reliability instead of project delivery.
//
// Run individual queries:
//   cue eval ./greener-homes/ -e deployment
//   cue eval ./greener-homes/ -e "impact_database_failure"
//   cue eval ./greener-homes/ -e critical_services
//   cue eval ./greener-homes/ -e risk_register
//   cue eval ./greener-homes/ -e platform_health
//   cue eval ./greener-homes/ -e summary
//   cue eval ./greener-homes/ -e service_categories
//   cue eval ./greener-homes/ -e rollback_plan
//   cue eval ./greener-homes/ -e dependency_chain
//   cue eval ./greener-homes/ -e immediate_dependents
//   cue eval ./greener-homes/ -e toon --out text

package main

import (
	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════════
// 1. DEPLOYMENT — Service startup order
// ═══════════════════════════════════════════════════════════════════════════════
//
// "What order do we bring services up after a full outage?"
//
// Layer 0 (external data) must be reachable before Layer 1 (databases),
// databases before compute, compute before quality, etc.

_plan: patterns.#DeploymentPlan & {Graph: platform}

deployment: {
	overview: _plan.summary
	layers: [
		for l in _plan.layers {
			layer:    l.layer
			gate:     l.gate
			services: l.resources
			count:    len(l.resources)
		},
	]
	startup_sequence:  _plan.startup_sequence
	shutdown_sequence: _plan.shutdown_sequence
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. IMPACT — Audit database failure
// ═══════════════════════════════════════════════════════════════════════════════
//
// "The PostgreSQL audit database is unresponsive — what's affected?"
//
// The audit database is the most-connected service. When it goes down,
// the HOT2000 engine can't validate submissions, the rebate engine
// can't calculate grants, and all downstream portals are degraded.

_db_impact: patterns.#ImpactQuery & {
	Graph:  platform
	Target: "audit-database"
}

_db_blast: patterns.#BlastRadius & {
	Graph:  platform
	Target: "audit-database"
}

impact_database_failure: {
	scenario:        "PostgreSQL audit-database server unresponsive"
	target:          "audit-database"
	total_affected:  _db_impact.affected_count
	affected_services: [for name, _ in _db_impact.affected {name}]
	rollback_order:    _db_blast.rollback_order
	startup_order:     _db_blast.startup_order
	safe_to_continue: [for name, _ in _db_blast.safe_peers {name}]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. CRITICAL SERVICES — Most-depended-upon components
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Which services should have the highest SLA and redundancy?"

_criticality: patterns.#CriticalityRank & {Graph: platform}

critical_services: {
	ranked: [
		for r in _criticality.ranked
		if r.dependents > 0 {
			service:             r.name
			downstream_affected: r.dependents
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. RISK REGISTER — Single points of failure
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Which services have no redundancy and high downstream impact?"
//
// For a government platform processing thousands of audit files,
// the HOT2000 engine and audit database are the two most critical SPOFs.

_spof: patterns.#SinglePointsOfFailure & {Graph: platform}

risk_register: {
	spof_count: _spof.summary.spof_count
	risks: [
		for r in _spof.risks {
			service:             r.name
			downstream_affected: r.dependents
			depth:               r.depth
			category: [
				if r.dependents > 10 {"CRITICAL"},
				if r.dependents > 5 {"HIGH"},
				if r.dependents > 2 {"MEDIUM"},
				"LOW",
			][0]
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. PLATFORM HEALTH — HOT2000 engine degraded
// ═══════════════════════════════════════════════════════════════════════════════
//
// "HOT2000 simulation workers are stuck — queue is growing. What's degraded?"
//
// When the simulation engine goes down, new audits can't be processed,
// EnerGuide labels can't be generated, and QA validation stops.
// But the rebate engine (which uses existing audit data) may still work.

_health: patterns.#HealthStatus & {
	Graph: platform
	Status: {
		"cwec-weather":   "healthy"
		"nrcan-registry": "healthy"
		"ieso-grid-data": "healthy"
		"hot2000-engine": "down" // simulation queue stuck, workers unresponsive
	}
}

platform_health: {
	scenario:      "HOT2000 simulation workers unresponsive — queue depth growing, no new audits processing"
	status_counts: _health.summary
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. SUMMARY — Platform metrics
// ═══════════════════════════════════════════════════════════════════════════════

_metrics: patterns.#GraphMetrics & {Graph: platform}

summary: {
	platform_name:       "Greener Homes — Ontario Regional Processing Platform"
	total_services:      _metrics.total_resources
	foundation_services: _metrics.root_count
	terminal_services:   _metrics.leaf_count
	service_layers:      _metrics.max_depth + 1
	dependency_links:    _metrics.total_edges
	spof_count:          _spof.summary.spof_count
	graph_valid:         platform.valid
	validation_issues:   validate.issues
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. SERVICE CATEGORIES — Group services by type
// ═══════════════════════════════════════════════════════════════════════════════
//
// "How many services do we have in each category?"

_byType: patterns.#GroupByType & {Graph: platform}

service_categories: {
	by_type: {
		for typeName, members in _byType.groups {
			(typeName): {
				services: [for m, _ in members {m}]
				count:    _byType.counts[typeName]
			}
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. ROLLBACK — Compute layer failure scenario
// ═══════════════════════════════════════════════════════════════════════════════
//
// "The simulation cluster crashed — what needs to be rolled back?"

_rollback: patterns.#RollbackPlan & {
	Graph:    platform
	FailedAt: 2 // Compute layer (hot2000-engine, ers-calculator, rebate-engine)
}

rollback_plan: {
	scenario:      "Compute layer failure — HOT2000 engine and dependent services"
	rollback_from: _rollback.summary
	undo_sequence: _rollback.sequence
	safe_services: _rollback.safe
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. DEPENDENCY CHAIN — Full predecessor trace
// ═══════════════════════════════════════════════════════════════════════════════
//
// "What must be running before the auditor portal works?"

_portal_chain: patterns.#DependencyChain & {
	Graph:  platform
	Target: "auditor-portal"
}

dependency_chain: {
	target:            "auditor-portal"
	path:              _portal_chain.path
	depth:             _portal_chain.depth
	predecessor_count: len([for _, _ in _portal_chain.ancestors {1}])
}

// ═══════════════════════════════════════════════════════════════════════════════
// 10. IMMEDIATE DEPENDENTS — Direct connections to audit database
// ═══════════════════════════════════════════════════════════════════════════════
//
// "What services connect directly to the audit database?"
// (vs #ImpactQuery which shows transitive dependents)

_db_direct: patterns.#ImmediateDependents & {
	Graph:  platform
	Target: "audit-database"
}

immediate_dependents: {
	target:   "audit-database"
	services: [for name, _ in _db_direct.dependents {name}]
	count:    _db_direct.count
}

// ═══════════════════════════════════════════════════════════════════════════════
// 11. TOON — Token-efficient export for LLM consumption
// ═══════════════════════════════════════════════════════════════════════════════
//
// ~55% fewer tokens than JSON when sending graph data to an LLM.
//
//   cue eval ./greener-homes/ -e toon --out text

_toon: patterns.#TOONExport & {
	Input: _resources
}

toon: _toon.TOON

// ═══════════════════════════════════════════════════════════════════════════════
// 12. VIZ — Pre-computed visualization data for D3.js explorer
// ═══════════════════════════════════════════════════════════════════════════════
//
//   cue export ./greener-homes/ -e viz --out json > greener-homes.json

_viz: patterns.#VizData & {
	Graph:     platform
	Resources: _resources
}

viz: {
	data:      _viz.data
	resources: _resources
}
