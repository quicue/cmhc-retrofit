# NotebookLM Podcast Prompt — CJLQ Demo

Upload this file plus the CUE source files as sources in NotebookLM,
then use the prompt below to generate a podcast episode.

## Sources to Upload

1. This file (`NOTEBOOKLM.md`)
2. `~/cjlq/nhcf/portfolio.cue`
3. `~/cjlq/nhcf/queries.cue`
4. `~/cjlq/greener-homes/platform.cue`
5. `~/cjlq/greener-homes/queries.cue`
6. `~/cjlq/README.md`

## Podcast Generation Prompt

```
Create a podcast episode titled "Graphs Instead of Gantt Charts:
What If Your Retrofit Program Could Debug Itself?"

Target audience: A sustainability energy engineer at CMHC who manages
NHCF deep retrofit programs and oversees EnerGuide audit quality for
Greener Homes. They use Primavera P6, HOT2000, eQUEST, and
spreadsheets daily. They're technically strong but haven't seen
infrastructure-as-code applied to program delivery before.

Structure:

1. HOOK (2 min)
   Start with a real scenario: "Rideau Tower's ASHP delivery is 8
   weeks late. You're the CMHC reviewer. How long does it take you
   to figure out what's affected?" Walk through the manual process
   (open P6, check predecessors, cross-reference with the risk
   register, email the PM). Then show the graph answer: one query,
   instant cascade analysis.

2. THE PROBLEM (3 min)
   Program oversight for deep retrofits is fragmented. The schedule
   is in P6, the energy models are in HOT2000/eQUEST, the risk
   register is a spreadsheet, the compliance check is a Word
   document. When something changes, you manually propagate the
   impact across all these artifacts. At portfolio scale (4+
   buildings, 270 units), this is error-prone and slow.

3. THE GRAPH APPROACH (5 min)
   Explain the core idea: every work package is a node, every
   predecessor relationship is an edge. The graph engine computes
   everything else — schedule phases, critical path, impact
   propagation, rollback sequences, health status. Use the NHCF
   example: 18 work packages from CMHC agreement through
   commissioning. Walk through how "rideau-audit depends_on
   consultant-procurement" becomes a computable schedule.

4. TWO SHAPES, ONE ENGINE (3 min)
   Show that the same vocabulary handles project delivery (NHCF —
   like a Gantt chart) AND infrastructure topology (Greener Homes —
   like a network diagram). The Greener Homes platform has 17
   services processing EnerGuide audits. When the audit database
   goes down, 11 of 17 services are affected. Same graph query,
   different domain.

5. REAL SPECS, REAL SCENARIOS (4 min)
   Walk through the Ontario energy data: NECB Zone 6, 4500 HDD,
   gas factor 49.88 kgCO2e/GJ, Ontario grid at 74 gCO2e/kWh.
   Show how the NHCF compliance query validates that all 4
   buildings exceed the 25% energy + 25% GHG minimum. Mention
   the building archetypes: 1972 concrete high-rise, 1965 brick
   walkup, 1978 row townhomes, 1968 mid-rise.

6. WHAT-IF SCENARIOS (3 min)
   Three scenarios from the queries:
   - Rideau Tower design delay → cascades to NHCF milestone + all
     construction
   - ASHP delivery delay → commissioning blocked, program closeout
     delayed
   - Commissioning finds ASHP underperformance → rollback sequence
     from phase 5

7. CLOSE (2 min)
   The key insight: when your program structure is a typed graph,
   every question a CMHC reviewer asks ("what's affected?", "are we
   compliant?", "what's the rollback?") is a graph query with a
   deterministic answer. No spreadsheet drift. No manual cascade
   tracing. The graph is the single source of truth.

Tone: Technical but accessible. Assume the listener knows NHCF
requirements, EnerGuide ratings, and HOT2000 — don't explain those.
DO explain the graph concepts and how they map to PM concepts they
already know (CPM, predecessors, float, what-if). Use concrete
numbers from the examples.
```

## Alternative Presentation Formats

### Slide Deck Outline (15 min talk)

1. Title: "Infrastructure-as-Graph for CMHC Program Delivery"
2. The problem: fragmented program oversight artifacts
3. One query: `cue eval -e impact_rideau_delay` (live demo)
4. How it works: declare dependencies, compute everything else
5. NHCF example: 18 work packages, 8 phases, real Ottawa specs
6. Greener Homes: same engine, infrastructure topology
7. PM concept mapping table (from README)
8. Live queries: schedule, critical_path, ghg_impact, compliance
9. What-if: three delay scenarios with cascade analysis
10. Visual explorer demo (D3.js graph on phone)
11. Key insight: graph = single source of truth

### Demo Script (5 min live demo)

```bash
# "Here's a 4-building NHCF portfolio in Ottawa."
cue eval ./nhcf/ -e summary

# "Are we NHCF compliant?"
cue eval ./nhcf/ -e nhcf_compliance

# "Rideau Tower design is 6 weeks late. What's affected?"
cue eval ./nhcf/ -e "impact_rideau_delay"

# "Where are the single points of failure?"
cue eval ./nhcf/ -e risk_register

# "Now the same tool, different shape — infrastructure."
cue eval ./greener-homes/ -e summary

# "Audit database goes down. Blast radius?"
cue eval ./greener-homes/ -e "impact_database_failure"
```

### One-Pager (email/print)

**Subject:** Typed Dependency Graphs for NHCF Program Oversight

**Problem:** Deep retrofit programs generate fragmented oversight
artifacts — schedules in P6, energy models in HOT2000, risk
registers in Excel, compliance checks in Word. Impact analysis
requires manual cross-referencing.

**Solution:** Model program work packages as a typed dependency
graph. Declare the structure once; compute schedule, critical path,
risk analysis, compliance, and what-if scenarios automatically.

**Demo:** 4-building Ottawa portfolio (270 units, 18,100 m2).
18 work packages from NHCF agreement through closeout. Real Zone 6
specs (4,500 HDD, OBC SB-12, gas 49.88 kgCO2e/GJ).

**Key queries:**
- `ghg_impact` — portfolio reduction: 744 to 165 tCO2e/yr (78%)
- `nhcf_compliance` — all buildings exceed 25% EUI + 25% GHG minimum
- `impact_rideau_delay` — design delay cascades to 4 downstream packages
- `risk_register` — 2 critical SPOFs (agreement, design review gate)

**Same engine, different shape:** Also models the Greener Homes
audit processing platform (17 services, 6 layers). Database failure
cascades to 11/17 services. Same graph query, different domain.
