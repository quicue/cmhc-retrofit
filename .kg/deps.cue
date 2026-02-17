// Dependency registry — patterns consumed from quicue.ca
package kg

// pattern definitions consumed (from quicue.ca/patterns@v0)
_pattern_deps: {
	"#InfraGraph": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/portfolio.cue", "nhcf/queries.cue", "greener-homes/platform.cue", "greener-homes/queries.cue"]
		purpose: "Dependency graph computation — depth, ancestors, topology"
	}
	"#ValidateGraph": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Graph schema validation"
	}
	"#DeploymentPlan": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Topological deployment ordering with layer gates"
	}
	"#CriticalityRank": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Critical path analysis — rank by downstream dependents"
	}
	"#ImpactQuery": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "What breaks if work package X slips"
	}
	"#BlastRadius": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Transitive impact scope of a delay or failure"
	}
	"#SinglePointsOfFailure": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Work packages whose delay cascades widely"
	}
	"#HealthStatus": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Health propagation — simulate delays and see downstream effects"
	}
	"#GroupByType": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Categorize work packages by @type"
	}
	"#RollbackPlan": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Recovery sequence computation"
	}
	"#DependencyChain": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Predecessor chain tracing"
	}
	"#ImmediateDependents": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Direct dependent extraction"
	}
	"#GraphMetrics": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Node count, edge count, max depth, graph statistics"
	}
	"#TOONExport": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Token-optimized compact export for LLM consumption"
	}
	"#VizData": {
		source:  "quicue.ca/patterns@v0"
		used_in: ["nhcf/queries.cue", "greener-homes/queries.cue"]
		purpose: "Pre-computed D3.js visualization data"
	}
}
