// Analysis Queries — What the graph tells you about the retrofit program
//
// Each expression answers a question a CMHC Principal, Technical Services
// asks during day-to-day oversight of NHCF-funded retrofits.
//
// Run individual queries:
//   cue eval ./nhcf/ -e schedule
//   cue eval ./nhcf/ -e critical_path
//   cue eval ./nhcf/ -e ghg_impact
//   cue eval ./nhcf/ -e "impact_rideau_delay"
//   cue eval ./nhcf/ -e risk_register
//   cue eval ./nhcf/ -e portfolio_health
//   cue eval ./nhcf/ -e nhcf_compliance
//   cue eval ./nhcf/ -e execution_plan
//   cue eval ./nhcf/ -e summary
//   cue eval ./nhcf/ -e cost_effectiveness
//   cue eval ./nhcf/ -e schedule_duration
//   cue eval ./nhcf/ -e dependency_chain
//   cue eval ./nhcf/ -e toon --out text

package main

import (
	"list"

	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════════
// 1. SCHEDULE — Phase-by-phase execution plan
// ═══════════════════════════════════════════════════════════════════════════════
//
// "What can run in parallel, and what has to wait?"
//
// Computed from dependency depth. Phase N cannot start until
// phases 0..(N-1) are complete. Within a phase, work is concurrent.

_plan: patterns.#DeploymentPlan & {Graph: program}

schedule: {
	overview: _plan.summary
	phases: [
		for l in _plan.layers {
			phase:         l.layer
			gate:          l.gate
			work_packages: l.resources
			count:         len(l.resources)
		},
	]
	execution_sequence: _plan.startup_sequence
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. CRITICAL PATH — Most downstream dependents
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Which work packages delay the most things if they slip?"
//
// A CMHC reviewer checks this to focus technical oversight on the
// highest-leverage items. If nhcf-agreement slips, everything slips.

_criticality: patterns.#CriticalityRank & {Graph: program}

critical_path: {
	ranked: [
		for r in _criticality.ranked
		if r.dependents > 0 {
			work_package:        r.name
			downstream_affected: r.dependents
			owner:               _work_packages[r.name].owner
			discipline:          _work_packages[r.name].discipline
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. GHG IMPACT — Portfolio greenhouse gas reduction analysis
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Are we meeting NHCF's 25% GHG reduction target? What's the portfolio picture?"
//
// This is the core technical question for a CMHC Principal reviewing
// an NHCF application. The numbers must be defensible.

ghg_impact: {
	portfolio_summary: {
		total_units:        270
		total_floor_area:   "18,100 m2"
		climate:            _climate.zone + " — " + _climate.weather_file
		baseline_ghg_total: _buildings["rideau-tower"].baseline_ghg + _buildings["gladstone-walkup"].baseline_ghg + _buildings["bayshore-townhomes"].baseline_ghg + _buildings["vanier-midrise"].baseline_ghg
		target_ghg_total:   _buildings["rideau-tower"].target_ghg + _buildings["gladstone-walkup"].target_ghg + _buildings["bayshore-townhomes"].target_ghg + _buildings["vanier-midrise"].target_ghg
		total_investment:   _buildings["rideau-tower"].estimated_cost + _buildings["gladstone-walkup"].estimated_cost + _buildings["bayshore-townhomes"].estimated_cost + _buildings["vanier-midrise"].estimated_cost
		grid_carbon_factor: "\(_carbon.grid_gco2e_per_kwh) gCO2e/kWh (Ontario IESO 2024)"
		gas_carbon_factor:  "\(_carbon.gas_kgco2e_per_gj) kgCO2e/GJ (NRCan)"
	}

	buildings: [
		for _, b in _buildings {
			name:              b.label
			archetype:         b.archetype
			year_built:        b.year_built
			units:             b.units
			floor_area_m2:     b.floor_area_m2
			model_tool:        b.model_tool
			baseline_eui:      b.baseline_eui
			target_eui:        b.target_eui
			eui_reduction_pct: b.eui_reduction_pct
			baseline_ghg:      b.baseline_ghg
			target_ghg:        b.target_ghg
			ghg_reduction_pct: b.ghg_reduction_pct
			estimated_cost:    b.estimated_cost
			retrofit_scope:    b.retrofit_scope
		},
	]

	code_reference: _code
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. IMPACT ANALYSIS — Rideau Tower design delay
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Rideau Tower design is running 6 weeks late — what's affected?"
//
// The tower is the largest building and longest construction phase.
// Design delays cascade through the NHCF milestone and into construction.

_rideau_impact: patterns.#ImpactQuery & {
	Graph:  program
	Target: "rideau-design"
}

_rideau_blast: patterns.#BlastRadius & {
	Graph:  program
	Target: "rideau-design"
}

impact_rideau_delay: {
	scenario:             "Rideau Tower design package running 6 weeks behind schedule"
	changed_work_package: "rideau-design"
	total_affected:       _rideau_impact.affected_count

	affected_work_packages: [for name, _ in _rideau_impact.affected {
		work_package: name
		owner:        _work_packages[name].owner
		discipline:   _work_packages[name].discipline
	}]

	recommended_stop_sequence:  _rideau_blast.rollback_order
	recommended_start_sequence: _rideau_blast.startup_order
	safe_to_continue: [for name, _ in _rideau_blast.safe_peers {name}]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. RISK REGISTER — Single points of failure
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Which work packages have no redundancy and high downstream impact?"
//
// In social housing retrofits, common SPOFs are: the consultant (single
// firm doing all audits), the NHCF design review (single gate), and
// commissioning (single party verifying all systems).

_spof: patterns.#SinglePointsOfFailure & {Graph: program}

risk_register: {
	spof_count: _spof.summary.spof_count
	risks: [
		for r in _spof.risks {
			work_package:        r.name
			downstream_affected: r.dependents
			schedule_phase:      r.depth
			category: [
				if r.dependents > 12 {"CRITICAL"},
				if r.dependents > 6 {"HIGH"},
				if r.dependents > 2 {"MEDIUM"},
				"LOW",
			][0]
			owner:      _work_packages[r.name].owner
			discipline: _work_packages[r.name].discipline
			mitigation: [
				if r.dependents > 12 {"Dedicated resources, schedule buffer, CMHC escalation path"},
				if r.dependents > 6 {"Weekly tracking, early procurement, backup supplier identified"},
				if r.dependents > 2 {"Monitor closely, maintain schedule float analysis"},
				"Standard tracking",
			][0]
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. PORTFOLIO HEALTH — Delay propagation scenario
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Rideau Tower retrofit is behind schedule — what's degraded?"
//
// Supply chain delays are the #1 schedule risk for deep retrofits.
// Cold-climate ASHP equipment has 12-16 week lead times.

_health: patterns.#HealthStatus & {
	Graph: program
	Status: {
		"nhcf-agreement":          "healthy"
		"consultant-procurement":  "healthy"
		"rideau-retrofit":         "down" // ASHP delivery delay, construction stalled
	}
}

portfolio_health: {
	scenario:      "Rideau Tower retrofit stalled — ASHP equipment delivery delayed 8 weeks"
	status_counts: _health.summary
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. NHCF COMPLIANCE — Program requirements check
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Does this portfolio meet NHCF minimum requirements?"
//
// The CMHC Technical Reviewer checks:
//   - >=25% EUI reduction (all buildings)
//   - >=25% GHG reduction (all buildings)
//   - Accessibility compliance (OBC)
//   - 20-year affordability covenant

_byType: patterns.#GroupByType & {Graph: program}

nhcf_compliance: {
	program:   "National Housing Co-Investment Fund — Repair Stream"
	applicant: "Ottawa Community Housing Corporation"
	requirements: {
		energy_reduction: {
			minimum: "25% EUI reduction"
			achieved: {
				for _, b in _buildings {
					(b.label): "\(b.eui_reduction_pct)% reduction (\(b.baseline_eui) to \(b.target_eui) ekWh/m2/yr)"
				}
			}
			_non_compliant: [for _, b in _buildings if b.eui_reduction_pct < 25 {b.label}]
			compliant: len(_non_compliant) == 0
		}
		ghg_reduction: {
			minimum: "25% GHG reduction"
			achieved: {
				for _, b in _buildings {
					(b.label): "\(b.ghg_reduction_pct)% reduction (\(b.baseline_ghg) to \(b.target_ghg) tCO2e/yr)"
				}
			}
			_non_compliant: [for _, b in _buildings if b.ghg_reduction_pct < 25 {b.label}]
			compliant: len(_non_compliant) == 0
		}
		accessibility: "Must meet current OBC accessibility standards — to be confirmed by architect"
		affordability: "20-year affordability covenant on all 270 units"
	}
	quality_gates: [
		for name, _ in _byType.groups.Milestone {
			work_package: name
			description:  _work_packages[name].description
			owner:        _work_packages[name].owner
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. EXECUTION PLAN — Rollback from a failed phase
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Commissioning found major ASHP performance issues — what do we undo?"

_rollback: patterns.#RollbackPlan & {
	Graph:    program
	FailedAt: 5 // Commissioning layer
}

execution_plan: {
	scenario:       "Commissioning (phase 5) reveals ASHP performance below design spec"
	rollback_from:  _rollback.summary
	undo_sequence:  _rollback.sequence
	safe_completed: _rollback.safe
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. SUMMARY — Overall program metrics
// ═══════════════════════════════════════════════════════════════════════════════

_metrics: patterns.#GraphMetrics & {Graph: program}

summary: {
	program_name:          "NHCF Deep Retrofit — Ottawa Community Housing"
	nhcf_stream:           "Repair"
	applicant:             "Ottawa Community Housing Corporation"
	climate_zone:          _climate.zone
	hdd:                   _climate.hdd
	portfolio_units:       270
	portfolio_floor_area:  "18,100 m2"
	total_work_packages:   _metrics.total_resources
	foundation_items:      _metrics.root_count
	terminal_deliverables: _metrics.leaf_count
	schedule_phases:       _metrics.max_depth + 1
	dependency_links:      _metrics.total_edges
	spof_count:            _spof.summary.spof_count
	graph_valid:           program.valid
	validation_issues:     validate.issues
}

// ═══════════════════════════════════════════════════════════════════════════════
// 10. COST EFFECTIVENESS — Investment metrics
// ═══════════════════════════════════════════════════════════════════════════════
//
// "Is this program cost-effective? How does it compare to sector benchmarks?"
//
// Deep retrofits in Canada typically run $35,000–$45,000/tCO2e avoided.
// The federal carbon price ($80/tCO2e in 2024) provides the revenue benchmark.

_total_cost: _buildings["rideau-tower"].estimated_cost + _buildings["gladstone-walkup"].estimated_cost + _buildings["bayshore-townhomes"].estimated_cost + _buildings["vanier-midrise"].estimated_cost
_baseline_ghg: _buildings["rideau-tower"].baseline_ghg + _buildings["gladstone-walkup"].baseline_ghg + _buildings["bayshore-townhomes"].baseline_ghg + _buildings["vanier-midrise"].baseline_ghg
_target_ghg: _buildings["rideau-tower"].target_ghg + _buildings["gladstone-walkup"].target_ghg + _buildings["bayshore-townhomes"].target_ghg + _buildings["vanier-midrise"].target_ghg
_ghg_avoided: _baseline_ghg - _target_ghg

cost_effectiveness: {
	portfolio: {
		total_investment:          _total_cost
		annual_ghg_avoided_tco2e: _ghg_avoided
		cost_per_tco2e_yr:        _total_cost / _ghg_avoided
		cost_per_unit:            _total_cost / 270
		cost_per_m2:              _total_cost / 18100
		annual_carbon_value:      _ghg_avoided * _carbon.carbon_price
		carbon_payback_years:     _total_cost / (_ghg_avoided * _carbon.carbon_price)
	}
	per_building: [
		for _, b in _buildings {
			name:           b.label
			units:          b.units
			cost_per_unit:  b.estimated_cost / b.units
			cost_per_m2:    b.estimated_cost / b.floor_area_m2
			ghg_avoided:    b.baseline_ghg - b.target_ghg
			cost_per_tco2e: b.estimated_cost / (b.baseline_ghg - b.target_ghg)
		},
	]
}

// ═══════════════════════════════════════════════════════════════════════════════
// 11. SCHEDULE DURATION — Phase-based critical path estimate
// ═══════════════════════════════════════════════════════════════════════════════
//
// "How long will the whole program take?"
//
// Each phase gates the next. Within a phase, work packages run in parallel.
// Total duration = sum of the longest work package in each phase.
// This is the CPM (Critical Path Method) forward-pass calculation.

schedule_duration: {
	by_phase: [
		for l in _plan.layers {
			phase:         l.layer
			work_packages: l.resources
			_durations: [for wp in l.resources {_work_packages[wp].duration_weeks}]
			max_weeks: list.Max(_durations)
		},
	]
	_phase_durations: [for p in by_phase {p.max_weeks}]
	total_weeks: list.Sum(_phase_durations)
}

// ═══════════════════════════════════════════════════════════════════════════════
// 12. DEPENDENCY CHAIN — Full predecessor trace
// ═══════════════════════════════════════════════════════════════════════════════
//
// "What's the full chain of predecessors for the closeout milestone?"
//
// Traces one path from nhcf-closeout back to a root.
// Note: follows first parent at each level (alphabetical in CUE).

_closeout_chain: patterns.#DependencyChain & {
	Graph:  program
	Target: "nhcf-closeout"
}

dependency_chain: {
	target:            "nhcf-closeout"
	path:              _closeout_chain.path
	depth:             _closeout_chain.depth
	predecessor_count: len([for _, _ in _closeout_chain.ancestors {1}])
}

// ═══════════════════════════════════════════════════════════════════════════════
// 13. TOON — Token-efficient export for LLM consumption
// ═══════════════════════════════════════════════════════════════════════════════
//
// ~55% fewer tokens than JSON when sending graph data to an LLM.
//
//   cue eval ./nhcf/ -e toon --out text

_toon: patterns.#TOONExport & {
	Input:  _work_packages
	Fields: ["name", "types", "discipline", "owner", "duration_weeks"]
}

toon: _toon.TOON

// ═══════════════════════════════════════════════════════════════════════════════
// 14. VIZ — Pre-computed visualization data for D3.js explorer
// ═══════════════════════════════════════════════════════════════════════════════
//
// Structured export: nodes, edges, topology, criticality, SPOF, coupling,
// and metrics — all pre-computed in CUE. The explorer reads this directly
// instead of re-computing graph analytics in JavaScript.
//
//   cue export ./nhcf/ -e viz --out json > nhcf.json

_viz: patterns.#VizData & {
	Graph:     program
	Resources: _work_packages
}

viz: {
	data:      _viz.data
	resources: _work_packages
}
