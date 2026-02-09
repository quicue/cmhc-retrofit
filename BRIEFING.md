# Typed Dependency Graphs for CMHC Program Delivery

**From:** quicue.ca demonstration project
**Date:** February 2026
**Visual explorer:** [rfam.cc/cjlq](https://rfam.cc/cjlq/)
**This briefing:** [rfam.cc/cjlq/briefing.html](https://rfam.cc/cjlq/briefing.html)

---

## What You're Looking At

This system models CMHC program delivery as a **typed dependency graph** — every work package, service, or milestone is a node, and every predecessor relationship is a directed edge. A graph engine computes schedule phases, impact propagation, compliance checks, and risk analysis automatically from the structure.

Two scenarios demonstrate the approach using your domain:

1. **NHCF Deep Retrofit** — a project delivery graph for a 4-building, 270-unit Ottawa Community Housing portfolio
2. **Greener Homes Platform** — an infrastructure topology graph for the Ontario regional EnerGuide processing platform

Same engine. Same patterns. Two fundamentally different shapes of work.

---

## Scenario 1: NHCF Deep Retrofit

### The Portfolio

| Building | Archetype | Year | Units | Area (m²) | Baseline EUI | Target EUI | Reduction | Baseline GHG | Target GHG | Cost |
|----------|-----------|------|-------|-----------|-------------|-----------|-----------|-------------|-----------|------|
| Rideau Tower | 12-storey concrete high-rise | 1972 | 150 | 8,500 | 310 ekWh/m²/yr | 120 | 61% | 393 tCO2e/yr | 89 | $12.5M |
| Gladstone Walk-up | 3-storey brick low-rise | 1965 | 24 | 1,800 | 260 | 95 | 63% | 70 | 15 | $1.8M |
| Bayshore Townhomes | Row townhomes (18 x 2 blocks) | 1978 | 36 | 3,600 | 200 | 75 | 62% | 107 | 23 | $3.2M |
| Vanier Mid-rise | 6-storey concrete mid-rise | 1968 | 60 | 4,200 | 280 | 105 | 62% | 174 | 38 | $5.5M |
| **Portfolio** | | | **270** | **18,100** | | | | **744** | **165** | **$23.0M** |

**Climate:** Ottawa, Ontario — NECB Zone 6, 4,500 HDD (18°C base), ASHRAE 99.6% design temp -29°C
**Weather file:** CWEC2020 Ottawa Intl Airport
**Energy modelling:** Part 3 buildings via eQUEST 3.65 (ASHRAE 90.1 App G), Part 9 via HOT2000 v11.10 (NRCan ERS)
**Carbon factors:** Natural gas 49.88 kgCO2e/GJ (NRCan), Ontario grid 74 gCO2e/kWh (IESO 2024 annual average)
**Code reference:** OBC SB-12 Zone 6 (2024), NECB 2020

### The Graph: 18 Work Packages, 27 Dependencies, 8 Phases

The system decomposes the retrofit program into 18 work packages with explicit finish-to-start predecessors. It then **computes** (not manually assigns) the schedule phases:

| Phase | Duration (max) | Work Packages | What's Happening |
|-------|---------------|---------------|-----------------|
| 0 | 12 weeks | nhcf-agreement | CMHC contribution agreement, scope, budget, 20-year affordability covenant |
| 1 | 6 weeks | consultant-procurement | Procure NRCan-licensed energy advisor (HOT2000 + eQUEST) |
| 2 | 4 weeks | rideau-audit, gladstone-audit, bayshore-audit, vanier-audit | Energy audits run in parallel — blower door, IR thermography, calibrated models |
| 3 | 10 weeks | portfolio-baseline, rideau-design, gladstone-design, bayshore-design, vanier-design | All designs and portfolio baseline in parallel; Rideau (10 wk) gates the phase |
| 4 | 3 weeks | nhcf-design-review | CMHC design milestone — confirm ≥25% EUI and ≥25% GHG reduction |
| 5 | 32 weeks | rideau-retrofit, gladstone-retrofit, bayshore-retrofit, vanier-retrofit | All construction in parallel; Rideau Tower (32 wk) is the long pole |
| 6 | 8 weeks | commissioning | Portfolio-wide systems commissioning — ASHP/VRF, HRV balancing, controls |
| 7 | 56 weeks | nhcf-closeout | 12-month M&V (IPMVP Option C), post-retrofit EnerGuide labels, final disbursement |
| **Total** | **131 weeks** | | **~2.5 years, program inception to NHCF closeout** |

The 131-week total is a CPM forward-pass estimate: the longest work package in each phase, summed. Within a phase, everything runs concurrently. The phase boundary is the gate — nothing in phase N+1 starts until phase N is complete.

> **Note:** This is a simplified critical-path calculation — finish-to-start dependencies only, no resource leveling, no calendars, no lags. Primavera P6 or MS Project handles those details better. The value here is that the phasing is *derived from the dependency structure*, not manually maintained, and it's the same engine that powers the infrastructure analysis below.

### What This Answers

#### "Which work packages delay the most things if they slip?"

The graph computes downstream impact for every node:

| Work Package | Downstream Affected | Owner | Phase |
|-------------|-------------------|-------|-------|
| nhcf-agreement | 17 (everything) | OCH Director of Asset Management | 0 |
| consultant-procurement | 16 | OCH Procurement | 1 |
| nhcf-design-review | 6 | CMHC Technical Reviewer | 4 |
| commissioning | 1 | Commissioning Agent | 6 |

The NHCF agreement and consultant procurement are the two highest-leverage items — if either slips, the entire program slips. You already know this intuitively. The graph proves it structurally and quantifies it.

#### "Rideau Tower design is running 6 weeks late — what's affected?"

- **7 work packages affected**: nhcf-design-review, all four construction packages, commissioning, nhcf-closeout
- **Safe to continue** (no impact from this delay): portfolio-baseline, gladstone-design, bayshore-design, vanier-design — these proceed independently
- **Recommended recovery sequence**: complete rideau-design first, then nhcf-design-review, then construction packages resume

This is blast radius analysis. P6 can trace predecessors (Trace Logic), but it answers "how much float is consumed?" not "what is the full downstream failure set?" This query answers the second question structurally — no manual tracing required.

#### "Rideau Tower retrofit stalled — ASHP equipment delivery delayed 8 weeks. What's degraded?"

Health propagation through the graph:

- **1 work package down**: rideau-retrofit (ASHP delivery stalled)
- **2 degraded** (transitively affected): commissioning, nhcf-closeout
- **15 healthy**: everything upstream of the construction phase is unaffected

Supply chain delays are the #1 schedule risk for deep retrofits. Cold-climate ASHP equipment has 12-16 week lead times. This query models what happens when equipment doesn't arrive — a concept borrowed from infrastructure monitoring (service health propagation), applied to project management.

#### "Does this portfolio meet NHCF minimum requirements?"

The system **computes** compliance, not asserts it. For each building:

- EUI reduction: all buildings achieve 61-63% (minimum 25%) ✓
- GHG reduction: all buildings achieve 77-78% (minimum 25%) ✓

If someone edits a building's numbers and drops below 25%, the schema itself catches the violation. There is no `compliant: true` flag that someone could forget to update — the check is structural, evaluated automatically whenever the data changes.

#### "Is this program cost-effective?"

| Metric | Portfolio | Rideau Tower | Gladstone | Bayshore | Vanier |
|--------|-----------|-------------|-----------|----------|--------|
| Cost/unit | $85,185 | $83,333 | $75,000 | $88,889 | $91,667 |
| Cost/m² | $1,271 | $1,471 | $1,000 | $889 | $1,310 |
| GHG avoided (tCO2e/yr) | 579 | 304 | 55 | 84 | 136 |
| Cost per tCO2e/yr avoided | $39,724 | $41,118 | $32,727 | $38,095 | $40,441 |

The cost per tCO2e/yr figures reflect **annual** emissions reductions. Over a 30-year measure life (standard for deep envelope retrofits), the portfolio cost is ~$1,324/tCO2e — well within range for social housing decarbonization. The annualized figures of $35,000–$45,000/tCO2e/yr align with current Canadian deep retrofit benchmarks.

Gladstone (the walk-up) is the most cost-effective at $32,727/tCO2e/yr — small low-rise buildings with individual systems are cheaper to retrofit per tonne than towers.

At the 2024 federal carbon price of $80/tCO2e, annual carbon value is $46,320/yr for the portfolio.

#### "What are the single points of failure?"

A SPOF is a work package where (a) other things depend on it, and (b) no peer of the same type exists at the same phase. The graph identifies 4:

| SPOF | Phase | Risk | Mitigation |
|------|-------|------|-----------|
| nhcf-agreement | 0 | CRITICAL — 17 downstream | Dedicated resources, schedule buffer, CMHC escalation path |
| consultant-procurement | 1 | CRITICAL — 16 downstream | Dedicated resources, backup supplier identified |
| nhcf-design-review | 4 | MEDIUM — 6 downstream | Monitor closely, maintain schedule float |
| commissioning | 6 | LOW — 1 downstream | Standard tracking |

The single-consultant dependency is a real risk in social housing retrofits. If the energy advisor firm can't deliver, there's no parallel path — all four audits go through them. This is a concept from infrastructure reliability engineering (single points of failure analysis) applied to project management — a query that P6 and MS Project don't have built in.

---

## Scenario 2: Greener Homes — Ontario Processing Platform

### The Platform

17 services across 6 deployment layers, processing residential EnerGuide audits at scale:

| Layer | Services | What It Does |
|-------|----------|-------------|
| 0 (External) | cwec-weather, nrcan-registry, ieso-grid-data | External data sources — weather, auditor credentials, grid emissions |
| 1 (Data) | audit-database, h2k-filestore, utility-datamart | PostgreSQL, MinIO object storage, utility billing integration |
| 2 (Compute) | hot2000-engine, ers-calculator, rebate-engine | Batch HOT2000 simulation, EnerGuide rating, rebate calculation |
| 3 (Quality) | qa-validator, ghg-tracker, reporting-api | QA scoring, portfolio GHG tracking, REST API |
| 4 (Presentation) | auditor-portal, program-dashboard, homeowner-portal | Web portals for advisors, executives, homeowners |
| 5 (Operations) | backup-service, monitoring | Nightly backup, Zabbix monitoring |

### What This Answers

#### "The audit database is down — what's affected?"

- **11 of 17 services affected** (65% of platform)
- **Safe to continue**: h2k-filestore, utility-datamart (they don't depend on the DB)
- **Recovery sequence**: bring up audit-database first, then compute layer, then quality, then portals
- The audit database is the single most critical component — more downstream dependents than any other service

#### "What must be running before the auditor portal works?"

The dependency chain for the auditor portal traces back 4 hops:
`auditor-portal → reporting-api → audit-database → nrcan-registry`

Plus 11 total predecessor services (transitive). If any of those 11 are down, the portal is degraded.

#### "Which services have no redundancy?"

2 single points of failure: **hot2000-engine** (simulation cluster) and **audit-database** (PostgreSQL primary). Both have high downstream impact and no same-type peer at their layer.

---

## The Interactive Explorer

**URL:** [rfam.cc/cjlq](https://rfam.cc/cjlq/)

The interactive graph explorer renders both scenarios as layered or force-directed network diagrams:

- **Tab switching**: click NHCF or Greener Homes to switch scenarios
- **Node selection**: click any node to see its details — description, types, dependencies, dependents, and impact count
- **Layer filtering**: toolbar buttons toggle visibility by phase/layer
- **Layout toggle**: switch between layered (phases top-to-bottom) and force-directed (organic clustering)
- **Deep linking**: share a specific node — e.g., `rfam.cc/cjlq/#nhcf/rideau-design`
- **Mobile-friendly**: bottom sheet interface on phones, side panel on desktop

All graph analytics are **pre-computed** and served as static JSON. The explorer is a pure renderer — no server, no database, no login required.

---

## What's New Here (and What Isn't)

This system doesn't replace Primavera P6 or MS Project. It does something different:

| Capability | Spreadsheet | P6 / MS Project | This System |
|-----------|-------------|-----------------|-------------|
| Schedule phasing (CPM) | Manual | **Yes** — full CPM with resource leveling, lags, calendars, float | Simplified — FS only, no lags/calendars. Derived from structure. |
| Impact propagation ("if X fails, what breaks?") | Manual tracing | Partial — Trace Logic shows float impact, not full downstream set | **Automatic** transitive closure — full downstream failure set |
| Health status propagation | Not possible | Not built-in | **Automatic** — concept from infrastructure monitoring |
| Compliance checking | Formulas (can be overridden) | Not built-in | **Structural constraint** — fails at schema level, can't be bypassed |
| Single point of failure detection | Manual analysis | Not built-in | **Computed** — no-redundancy + high-impact |
| Works for both project delivery *and* infrastructure topology | Separate models | PM only | **Same engine, same patterns** |
| Version-controlled, diffable, auditable | Limited | Binary / database files | **Plain text, git-tracked** |

> **The core idea:** The analytical queries — blast radius, health propagation, SPOF detection, structural compliance — are derived automatically from the dependency structure. The same engine that models a 4-building retrofit program also models a 17-service processing platform. When the data changes, every analysis recomputes. There is no report that gets out of sync with the plan.

---

## Technical Notes

### Data Sources and Methodology

- **Climate data**: Climate Atlas of Canada, CWEC2020 Typical Meteorological Year data for Ottawa Intl Airport (ASHRAE/NECB standard reference station for Zone 6)
- **Carbon factors**: Natural gas 49.88 kgCO2e/GJ per NRCan GHG Inventory; Ontario grid 74 gCO2e/kWh per IESO 2024 Annual Report
- **Building code**: OBC SB-12 (2024 edition) for Part 9 prescriptive; NECB 2020 for Part 3 performance
- **Energy modelling tools**: HOT2000 v11.10 for Part 9 (NRCan ERS protocol); eQUEST 3.65 for Part 3 (ASHRAE 90.1 Appendix G)
- **NHCF requirements**: National Housing Co-Investment Fund — Repair Stream (min 25% EUI reduction, min 25% GHG reduction, 20-year affordability covenant)
- **Carbon pricing**: $80/tCO2e, 2024 federal backstop rate

### What This Is Built On

The system uses [CUE](https://cuelang.org/), a typed configuration language originally developed at Google for infrastructure management. The same graph patterns that model datacenter dependency networks are applied here to model program delivery and platform topology.

The patterns are reusable: the graph engine computes depth, ancestors, and topology; the deployment planner generates phased execution sequences; the impact query traces failure propagation; and the SPOF detector finds nodes with no redundancy. These patterns work identically whether the nodes are work packages, services, containers, or any typed resource with dependencies.
