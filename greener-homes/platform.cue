// Greener Homes — Technical Platform Infrastructure
//
// Models the IT platform that processes residential EnerGuide audits
// at scale for Ontario. Unlike the NHCF scenario (a project delivery
// graph), this is an infrastructure dependency graph — databases,
// compute services, APIs, and dashboards.
//
// Same quicue.ca patterns, fundamentally different domain shape:
//   NHCF      = project phases   (audit → design → build → commission)
//   Greener   = service topology (data → compute → quality → presentation)
//
// This is the system a CMHC Technical Services team operates to
// process thousands of pre/post-retrofit EnerGuide audits across Ontario.
//
// Run:
//   cue vet  ./greener-homes/
//   cue eval ./greener-homes/ -e deployment
//   cue eval ./greener-homes/ -e "impact_database_failure"
//   cue eval ./greener-homes/ -e critical_services
//   cue eval ./greener-homes/ -e risk_register
//   cue eval ./greener-homes/ -e platform_health
//   cue eval ./greener-homes/ -e summary

package main

import (
	"quicue.ca/patterns@v0"
)

_base: "https://greener-homes.example.ca/platform/"

_resources: [Name=string]: {"@id": _base + Name, name: Name}
_resources: {

	// ─── EXTERNAL DATA SOURCES ───────────────────────────────────────────
	//
	// Foundation services that the platform depends on.
	// These are external — the platform consumes but does not control them.

	"cwec-weather": {
		name:        "cwec-weather"
		description: "CWEC2020 weather data — Ottawa Intl Airport, hourly TMY for Zone 6 simulations"
		"@type": {DataSource: true, External: true}
		ip:   "10.100.1.10"
		host: "weather-nfs"
		provides: {weather_data: true}
	}

	"nrcan-registry": {
		name:        "nrcan-registry"
		description: "NRCan Service Organization registry — energy advisor credentials and licensing status"
		"@type": {DataSource: true, External: true, Identity: true}
		fqdn: "api.nrcan.gc.ca"
		provides: {auditor_credentials: true}
	}

	"ieso-grid-data": {
		name:        "ieso-grid-data"
		description: "IESO Ontario grid emissions — hourly marginal and average carbon intensity (gCO2e/kWh)"
		"@type": {DataSource: true, External: true}
		fqdn: "reports.ieso.ca"
		provides: {grid_emissions: true}
	}

	// ─── DATA LAYER ──────────────────────────────────────────────────────
	//
	// Persistent storage for audit records, simulation files, and utility data.

	"audit-database": {
		name:        "audit-database"
		description: "PostgreSQL 16 — audit records, homeowner applications, rebate calculations, auditor performance history"
		"@type": {Database: true, CriticalInfra: true}
		ip:   "10.100.2.10"
		host: "db-primary"
		provides: {audit_records: true, rebate_data: true}
		depends_on: {"nrcan-registry": true}
	}

	"h2k-filestore": {
		name:        "h2k-filestore"
		description: "MinIO object storage — HOT2000 .h2k model files, energy model archives, audit photos"
		"@type": {Storage: true, CriticalInfra: true}
		ip:   "10.100.2.20"
		host: "minio-cluster"
		provides: {h2k_files: true}
		depends_on: {"cwec-weather": true}
	}

	"utility-datamart": {
		name:        "utility-datamart"
		description: "Utility data integration — Enbridge gas billing, Hydro Ottawa and LDC electricity consumption"
		"@type": {Database: true, Analytics: true}
		ip:   "10.100.2.30"
		host: "analytics-db"
		provides: {utility_data: true}
		depends_on: {"ieso-grid-data": true}
	}

	// ─── COMPUTE LAYER ───────────────────────────────────────────────────
	//
	// Simulation engines and calculation services.
	// HOT2000 is the NRCan-mandated tool for Part 9 residential energy modelling.

	"hot2000-engine": {
		name:        "hot2000-engine"
		description: "Batch HOT2000 simulation engine — headless v11.10, 8-worker pool, processes .h2k files against CWEC weather"
		"@type": {Compute: true, CriticalInfra: true}
		ip:   "10.100.3.10"
		host: "sim-cluster"
		provides: {simulation_results: true}
		depends_on: {
			"h2k-filestore":  true
			"audit-database": true
		}
	}

	"ers-calculator": {
		name:        "ers-calculator"
		description: "EnerGuide Rating System calculator — GJ/yr total energy, ERS score (0-100), PDF label generation"
		"@type": {Compute: true, Reporting: true}
		ip:   "10.100.3.20"
		host: "ers-service"
		provides: {ers_ratings: true, energuide_labels: true}
		depends_on: {"hot2000-engine": true}
	}

	"rebate-engine": {
		name:        "rebate-engine"
		description: "Rebate calculation service — measure eligibility, grant amounts, Greener Homes caps ($5,000 + $600 audit)"
		"@type": {Compute: true, Financial: true}
		ip:   "10.100.3.30"
		host: "rebate-service"
		provides: {rebate_calculations: true}
		depends_on: {
			"audit-database":   true
			"utility-datamart": true
		}
	}

	// ─── QUALITY + ANALYTICS ─────────────────────────────────────────────
	//
	// Quality assurance, GHG tracking, and program metrics aggregation.

	"qa-validator": {
		name:        "qa-validator"
		description: "QA service — HOT2000 model validation, outlier detection, audit quality scoring, 10% sample verification"
		"@type": {QualityAssurance: true, Analytics: true}
		ip:   "10.100.4.10"
		host: "qa-service"
		provides: {quality_scores: true}
		depends_on: {
			"hot2000-engine": true
			"ers-calculator":  true
		}
	}

	"ghg-tracker": {
		name:        "ghg-tracker"
		description: "Portfolio GHG tracker — aggregates per-home CO2e savings, forecasts program-level reduction vs federal targets"
		"@type": {Analytics: true, Reporting: true}
		ip:   "10.100.4.20"
		host: "ghg-service"
		provides: {ghg_projections: true}
		depends_on: {
			"rebate-engine":    true
			"ers-calculator":   true
			"utility-datamart": true
		}
	}

	"reporting-api": {
		name:        "reporting-api"
		description: "REST API — program metrics, audit status, rebate tracking, auditor performance KPIs"
		"@type": {API: true, CriticalInfra: true}
		ip:   "10.100.4.30"
		host: "api-gateway"
		provides: {program_metrics: true}
		depends_on: {
			"audit-database": true
			"rebate-engine":  true
		}
	}

	// ─── PRESENTATION LAYER ──────────────────────────────────────────────
	//
	// Web portals for energy advisors, program managers, and homeowners.

	"auditor-portal": {
		name:        "auditor-portal"
		description: "Energy advisor web portal — submit .h2k files, view QA results, access training materials"
		"@type": {WebApp: true}
		fqdn: "advisors.greener-homes.gc.ca"
		host: "web-cluster"
		provides: {auditor_access: true}
		depends_on: {
			"reporting-api": true
			"qa-validator":  true
		}
	}

	"program-dashboard": {
		name:        "program-dashboard"
		description: "Executive dashboard — registrations, completions, GHG savings, regional heat maps, auditor KPIs"
		"@type": {WebApp: true, Reporting: true}
		fqdn: "dashboard.greener-homes.gc.ca"
		host: "web-cluster"
		provides: {executive_reporting: true}
		depends_on: {
			"reporting-api": true
			"ghg-tracker":   true
		}
	}

	"homeowner-portal": {
		name:        "homeowner-portal"
		description: "Homeowner self-service — application status, audit scheduling, rebate tracking, EnerGuide label download"
		"@type": {WebApp: true}
		fqdn: "my.greener-homes.gc.ca"
		host: "web-cluster"
		provides: {homeowner_access: true}
		depends_on: {"reporting-api": true}
	}

	// ─── OPERATIONS ──────────────────────────────────────────────────────

	"backup-service": {
		name:        "backup-service"
		description: "Automated nightly backup — audit-database (pg_dump), .h2k file archive, 90-day retention"
		"@type": {Operations: true, Backup: true}
		ip:   "10.100.5.10"
		host: "backup-node"
		depends_on: {
			"audit-database": true
			"h2k-filestore":  true
		}
	}

	monitoring: {
		name:        "monitoring"
		description: "Zabbix monitoring — simulation queue depth, API latency, DB replication lag, disk usage alerts"
		"@type": {Operations: true, Monitoring: true}
		ip:   "10.100.5.20"
		host: "monitoring-node"
		depends_on: {
			"hot2000-engine": true
			"reporting-api":  true
			"qa-validator":   true
		}
	}
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUILD THE PLATFORM GRAPH
// ═══════════════════════════════════════════════════════════════════════════════
//
// 17 services, 6 deployment layers.
// The graph shows the full service topology from external data sources
// through compute and quality layers to user-facing portals.

platform: patterns.#InfraGraph & {Input: _resources}

validate: patterns.#ValidateGraph & {Input: _resources}
