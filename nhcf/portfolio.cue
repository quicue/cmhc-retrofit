// NHCF Deep Retrofit — Ottawa Community Housing Portfolio
//
// Models a National Housing Co-Investment Fund (NHCF) deep energy retrofit
// program as a dependency graph. Every work package is a graph node.
// The graph engine computes schedule phases, critical paths, and impact
// propagation — analysis a program manager does manually with Primavera P6
// or spreadsheets, but here it's declarative, typed, and auditable.
//
// Concepts mapping:
//   Infrastructure          → Retrofit Program
//   ──────────────────────────────────────────────
//   Resource                → Work Package
//   depends_on              → Predecessor (finish-to-start)
//   @type                   → Program phase / discipline tag
//   _depth (computed)       → Schedule phase (early-start layer)
//   _ancestors (computed)   → Full predecessor chain
//   roots                   → Program foundations (no predecessors)
//   leaves                  → Final deliverables (nothing downstream)
//
// Portfolio: 4 buildings, 270 units, 18,100 m²
// Climate:   Ottawa, Ontario — NECB Zone 6 (4,500 HDD)
// Program:   NHCF Repair Stream (min 25% energy + 25% GHG reduction)
//
// Run:
//   cue vet  ./nhcf/
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
	"quicue.ca/patterns@v0"
)

// ═══════════════════════════════════════════════════════════════════════════════
// CONSTANTS — Ontario / Ottawa energy parameters
// ═══════════════════════════════════════════════════════════════════════════════
//
// Sources:
//   Climate:  Climate Atlas of Canada, CWEC2020 TMY data
//   Carbon:   NRCan (gas), IESO Ontario 2024 annual report (grid)
//   Code:     Ontario Building Code SB-12 (2024), NECB 2020
//   Rates:    Enbridge Gas (Rate 6), Hydro Ottawa (TOU)

_climate: {
	zone:            "NECB Zone 6"
	hdd:             4500  // Heating Degree Days (18°C base), Ottawa Intl Airport
	design_temp_c:   -29   // ASHRAE 99.6% heating design temperature
	weather_file:    "CWEC2020 Ottawa Intl Airport"
}

_carbon: {
	gas_kgco2e_per_gj:  49.88  // Natural gas combustion, NRCan standard
	grid_gco2e_per_kwh: 74     // Ontario IESO 2024 annual average
	carbon_price:       80     // $/tCO2e, federal backstop 2024
}

_code: {
	standard:      "OBC SB-12 (Zone 6, 2024)"
	wall_r:        "R-24 effective (code min), R-40+ (NZE ready)"
	attic_r:       "R-50 to R-60"
	foundation_r:  "R-20 (below grade)"
	window_u:      "U-1.6 W/m²K (code), U-0.8 (NZE triple-glazed)"
	airtight:      "2.5 ACH@50Pa (code), <1.0 ACH@50Pa (NZE target)"
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUILDING INVENTORY — Ottawa Community Housing (OCH) Portfolio
// ═══════════════════════════════════════════════════════════════════════════════
//
// Energy data from pre-retrofit EnerGuide audits.
// Part 9 buildings (≤3 storeys, residential): HOT2000 v11.10 per NRCan ERS
// Part 3 buildings (>3 storeys or >600 m²): eQUEST 3.65 per ASHRAE 90.1
//
// EUI  = Energy Use Intensity (ekWh/m²/yr, site energy, all fuels)
// GHG  = Greenhouse gas emissions (tCO2e/yr)
// Reduction percentages pre-computed from baseline/target values.

_buildings: {
	"rideau-tower": {
		label:              "Rideau Tower"
		archetype:          "12-storey concrete high-rise"
		year_built:         1972
		units:              150
		floor_area_m2:      8500
		heating_system:     "Central gas boiler (2x Cleaver-Brooks, 1994)"
		model_tool:         "eQUEST 3.65 (Part 3)"
		baseline_eui:       310 // ekWh/m²/yr
		target_eui:         120 // overcladding + ASHP
		eui_reduction_pct:  61  // (310-120)/310
		baseline_ghg:       393 // tCO2e/yr (gas ~336 + elec ~57)
		target_ghg:         89  // tCO2e/yr (gas ~23 + elec ~66)
		ghg_reduction_pct:  77
		gas_share_pct:      71  // % of baseline from natural gas
		retrofit_scope:     "Overcladding (R-24 CI), triple-glazed windows (U-0.8), central ASHP (COP 3.2), suite HRVs (70% SRE)"
		estimated_cost:     12500000
	}
	"gladstone-walkup": {
		label:              "Gladstone Walk-up"
		archetype:          "3-storey brick low-rise"
		year_built:         1965
		units:              24
		floor_area_m2:      1800
		heating_system:     "Individual gas furnaces (80% AFUE average)"
		model_tool:         "HOT2000 v11.10 (Part 9)"
		baseline_eui:       260
		target_eui:         95
		eui_reduction_pct:  63
		baseline_ghg:       70
		target_ghg:         15
		ghg_reduction_pct:  78
		gas_share_pct:      71
		retrofit_scope:     "Exterior mineral wool (R-22 CI), triple-pane windows, per-unit cold-climate ASHP, HRVs"
		estimated_cost:     1800000
	}
	"bayshore-townhomes": {
		label:              "Bayshore Townhomes"
		archetype:          "Row townhomes (18 units x 2 blocks)"
		year_built:         1978
		units:              36
		floor_area_m2:      3600
		heating_system:     "Individual gas furnaces (80% AFUE average)"
		model_tool:         "HOT2000 v11.10 (Part 9)"
		baseline_eui:       200
		target_eui:         75
		eui_reduction_pct:  62
		baseline_ghg:       107
		target_ghg:         23
		ghg_reduction_pct:  78
		gas_share_pct:      70
		retrofit_scope:     "Attic blown cellulose (R-60), wall insulation (R-22 CI), windows, ASHP, HRVs"
		estimated_cost:     3200000
	}
	"vanier-midrise": {
		label:              "Vanier Mid-rise"
		archetype:          "6-storey concrete mid-rise"
		year_built:         1968
		units:              60
		floor_area_m2:      4200
		heating_system:     "Central gas boiler (Weil-McLain, 1998)"
		model_tool:         "eQUEST 3.65 (Part 3)"
		baseline_eui:       280
		target_eui:         105
		eui_reduction_pct:  62
		baseline_ghg:       174
		target_ghg:         38
		ghg_reduction_pct:  78
		gas_share_pct:      70
		retrofit_scope:     "Overcladding (R-20 CI), windows (U-1.0), VRF heat pump system, corridor HRVs"
		estimated_cost:     5500000
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// WORK BREAKDOWN STRUCTURE
// ═══════════════════════════════════════════════════════════════════════════════
//
// 18 work packages modelling the NHCF deep retrofit delivery.
// Schedule phases are computed from dependency depth, not manually assigned.
//
// Types (struct-as-set):
//   Program       — Program-level activity
//   Assessment    — Energy audit / data collection
//   Design        — Retrofit design work
//   Milestone     — NHCF or quality gate
//   Retrofit      — Construction activity
//   Commissioning — Systems commissioning / testing
//   MV            — Measurement & Verification
//   CriticalPath  — On critical path (highest downstream dependents)

_base: "https://och.example.ca/nhcf-retrofit/"

_work_packages: [Name=string]: {"@id": _base + Name, name: Name}
_work_packages: {

	// ─── PROGRAM FOUNDATION ──────────────────────────────────────────────

	"nhcf-agreement": {
		name:        "nhcf-agreement"
		description: "CMHC contribution agreement — scope, budget, milestones, 20-year affordability covenant"
		"@type": {Program: true, Milestone: true}
		discipline:     "program"
		owner:          "OCH Director of Asset Management"
		duration_weeks: 12
	}

	"consultant-procurement": {
		name:        "consultant-procurement"
		description: "Procure NRCan-licensed energy advisor (HOT2000 + eQUEST) and building science consultant"
		"@type": {Program: true}
		discipline:     "program"
		owner:          "OCH Procurement"
		duration_weeks: 6
		depends_on: {"nhcf-agreement": true}
	}

	// ─── ENERGY AUDITS ───────────────────────────────────────────────────
	//
	// Each building gets a full energy audit with calibrated simulation model.
	// Part 3 (>600 m², >3 storeys): eQUEST per ASHRAE 90.1 Appendix G
	// Part 9 (residential ≤3 storeys): HOT2000 per NRCan ERS protocol

	"rideau-audit": {
		name:        "rideau-audit"
		description: "Rideau Tower — eQUEST energy model, blower door, IR thermography, boiler efficiency test"
		"@type": {Assessment: true, CriticalPath: true}
		discipline:     "energy"
		owner:          "Energy Advisor"
		duration_weeks: 4
		building:       "rideau-tower"
		depends_on: {"consultant-procurement": true}
	}

	"gladstone-audit": {
		name:        "gladstone-audit"
		description: "Gladstone Walk-up — HOT2000 energy model per NRCan ERS, blower door (per-unit sampling)"
		"@type": {Assessment: true}
		discipline:     "energy"
		owner:          "Energy Advisor"
		duration_weeks: 3
		building:       "gladstone-walkup"
		depends_on: {"consultant-procurement": true}
	}

	"bayshore-audit": {
		name:        "bayshore-audit"
		description: "Bayshore Townhomes — HOT2000 energy model (representative unit + extrapolation to block)"
		"@type": {Assessment: true}
		discipline:     "energy"
		owner:          "Energy Advisor"
		duration_weeks: 3
		building:       "bayshore-townhomes"
		depends_on: {"consultant-procurement": true}
	}

	"vanier-audit": {
		name:        "vanier-audit"
		description: "Vanier Mid-rise — eQUEST energy model, envelope condition assessment, mechanical efficiency"
		"@type": {Assessment: true}
		discipline:     "energy"
		owner:          "Energy Advisor"
		duration_weeks: 4
		building:       "vanier-midrise"
		depends_on: {"consultant-procurement": true}
	}

	// ─── PORTFOLIO ANALYSIS + RETROFIT DESIGN ────────────────────────────

	"portfolio-baseline": {
		name:        "portfolio-baseline"
		description: "Aggregate portfolio EUI/GHG baseline — validate >=25% reduction achievable per NHCF requirement"
		"@type": {Assessment: true, Milestone: true, CriticalPath: true}
		discipline:     "energy"
		owner:          "Energy Advisor"
		duration_weeks: 2
		depends_on: {
			"rideau-audit":    true
			"gladstone-audit": true
			"bayshore-audit":  true
			"vanier-audit":    true
		}
	}

	"rideau-design": {
		name:        "rideau-design"
		description: "Tower retrofit design — overcladding details, ASHP sizing, HRV layout, electrical service upgrade"
		"@type": {Design: true, CriticalPath: true}
		discipline:     "engineering"
		owner:          "Lead Designer"
		duration_weeks: 10
		building:       "rideau-tower"
		depends_on: {"rideau-audit": true}
	}

	"gladstone-design": {
		name:        "gladstone-design"
		description: "Walk-up retrofit design — exterior insulation, window specs, per-unit ASHP, ventilation strategy"
		"@type": {Design: true}
		discipline:     "engineering"
		owner:          "Lead Designer"
		duration_weeks: 6
		building:       "gladstone-walkup"
		depends_on: {"gladstone-audit": true}
	}

	"bayshore-design": {
		name:        "bayshore-design"
		description: "Townhome retrofit design — attic/wall insulation, window replacement, ASHP selection"
		"@type": {Design: true}
		discipline:     "engineering"
		owner:          "Lead Designer"
		duration_weeks: 6
		building:       "bayshore-townhomes"
		depends_on: {"bayshore-audit": true}
	}

	"vanier-design": {
		name:        "vanier-design"
		description: "Mid-rise retrofit design — overcladding spec, VRF heat pump system, corridor ventilation"
		"@type": {Design: true}
		discipline:     "engineering"
		owner:          "Lead Designer"
		duration_weeks: 8
		building:       "vanier-midrise"
		depends_on: {"vanier-audit": true}
	}

	// ─── NHCF DESIGN MILESTONE ───────────────────────────────────────────

	"nhcf-design-review": {
		name:        "nhcf-design-review"
		description: "CMHC design phase milestone — energy models confirm >=25% EUI and >=25% GHG reduction"
		"@type": {Milestone: true, CriticalPath: true}
		discipline:     "program"
		owner:          "CMHC Technical Reviewer"
		duration_weeks: 3
		depends_on: {
			"portfolio-baseline": true
			"rideau-design":      true
			"gladstone-design":   true
			"bayshore-design":    true
			"vanier-design":      true
		}
	}

	// ─── CONSTRUCTION ────────────────────────────────────────────────────
	//
	// All construction gated on nhcf-design-review (CMHC approval).
	// Occupied buildings: tenant relocation phasing for tower/mid-rise.

	"rideau-retrofit": {
		name:        "rideau-retrofit"
		description: "Tower — overcladding, windows, ASHP + HRV, electrical upgrades, occupied phasing (32 weeks)"
		"@type": {Retrofit: true, CriticalPath: true}
		discipline:     "construction"
		owner:          "General Contractor"
		duration_weeks: 32
		building:       "rideau-tower"
		depends_on: {"nhcf-design-review": true}
	}

	"gladstone-retrofit": {
		name:        "gladstone-retrofit"
		description: "Walk-up — exterior insulation, windows, per-unit ASHP, HRV, gas furnace decommission"
		"@type": {Retrofit: true}
		discipline:     "construction"
		owner:          "General Contractor"
		duration_weeks: 16
		building:       "gladstone-walkup"
		depends_on: {"nhcf-design-review": true}
	}

	"bayshore-retrofit": {
		name:        "bayshore-retrofit"
		description: "Townhomes — attic insulation, wall insulation, windows, ASHP, HRV, unit-by-unit sequencing"
		"@type": {Retrofit: true}
		discipline:     "construction"
		owner:          "General Contractor"
		duration_weeks: 20
		building:       "bayshore-townhomes"
		depends_on: {"nhcf-design-review": true}
	}

	"vanier-retrofit": {
		name:        "vanier-retrofit"
		description: "Mid-rise — overcladding, windows, VRF heat pump, corridor HRVs, boiler decommission"
		"@type": {Retrofit: true}
		discipline:     "construction"
		owner:          "General Contractor"
		duration_weeks: 24
		building:       "vanier-midrise"
		depends_on: {"nhcf-design-review": true}
	}

	// ─── COMMISSIONING + CLOSEOUT ────────────────────────────────────────

	commissioning: {
		name:        "commissioning"
		description: "Portfolio-wide systems commissioning — ASHP/VRF performance, HRV balancing, controls verification"
		"@type": {Commissioning: true, Milestone: true}
		discipline:     "commissioning"
		owner:          "Commissioning Agent"
		duration_weeks: 8
		depends_on: {
			"rideau-retrofit":    true
			"gladstone-retrofit": true
			"bayshore-retrofit":  true
			"vanier-retrofit":    true
		}
	}

	"nhcf-closeout": {
		name:        "nhcf-closeout"
		description: "12-month M&V (IPMVP Option C), post-retrofit EnerGuide labels, NHCF compliance report, final disbursement"
		"@type": {Program: true, Milestone: true, MV: true}
		discipline:     "program"
		owner:          "OCH Director of Asset Management"
		duration_weeks: 56
		depends_on: {commissioning: true}
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUILD THE PROGRAM GRAPH
// ═══════════════════════════════════════════════════════════════════════════════
//
// #InfraGraph computes:
//   _depth     — schedule phase (early-start layer number)
//   _ancestors — full predecessor chain (transitive closure)
//   _path      — one path back to a root work package
//   topology   — work packages grouped by phase
//   roots      — foundation items (no predecessors)
//   leaves     — terminal deliverables (nothing downstream)
//
// Same computation as CPM forward pass, at schema evaluation time.
// 18 nodes, 8 schedule phases (depth 0–7).

program: patterns.#InfraGraph & {Input: _work_packages}

validate: patterns.#ValidateGraph & {Input: _work_packages}
