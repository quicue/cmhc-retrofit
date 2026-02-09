# cjlq — Infrastructure-as-Graph for CMHC Programs

**Audience:** Sustainability energy engineer doing project management
at CMHC — someone who reviews NHCF funding applications, oversees
energy modelling quality, and tracks portfolio-level GHG targets.

**What this is:** Two worked examples showing typed dependency graphs
applied to program oversight — complementing (not replacing) P6.
Every work package (or platform service) is a graph node. The graph
engine computes schedule phases, critical paths, risk registers, and
impact propagation — declaratively, with no code.

## Setup

Requires [CUE](https://cuelang.org/) v0.15.3 and a local checkout of
[quicue.ca](https://github.com/mthdn/quicue.ca).

```bash
# Symlink the quicue.ca vocabulary (one-time)
mkdir -p ~/cjlq/cue.mod/pkg
ln -s ~/quicue.ca ~/cjlq/cue.mod/pkg/quicue.ca
```

## Quick Start

```bash
# Validate
cue vet ./nhcf/
cue vet ./greener-homes/

# Key queries
cue eval ./nhcf/ -e summary
cue eval ./nhcf/ -e ghg_impact
cue eval ./nhcf/ -e nhcf_compliance
cue eval ./greener-homes/ -e summary
cue eval ./greener-homes/ -e deployment
```

## Visual Explorer

Interactive D3.js graph visualization with dependency highlighting,
layer filtering, and impact analysis. Phone-friendly.

```bash
# Build (exports JSON from CUE)
bash ~/cjlq/build.sh

# Local preview
python3 -m http.server -d ~/cjlq 8082
# then open http://localhost:8082

# Deep links (once deployed to rfam.cc)
# https://rfam.cc/cjlq/#nhcf
# https://rfam.cc/cjlq/#nhcf/rideau-design
# https://rfam.cc/cjlq/#greener-homes/audit-database
```

## Scenarios

### 1. NHCF Deep Retrofit (`nhcf/`)

A National Housing Co-Investment Fund deep energy retrofit program
for an Ottawa Community Housing portfolio.

**Portfolio:** 4 buildings, 270 units, 18,100 m²
**Graph:** 18 work packages, 27 edges, 8 schedule phases

The graph models program delivery the same way you'd set up a CPM
schedule in Primavera P6 — but the schedule, critical path, and
risk analysis are computed from the dependency structure, not
manually assigned.

| Query | What it answers |
|-------|----------------|
| `schedule` | What can run in parallel? What has to wait? |
| `critical_path` | Which packages delay the most if they slip? |
| `ghg_impact` | Portfolio EUI/GHG reduction vs NHCF targets |
| `impact_rideau_delay` | Rideau Tower design is late — cascade? |
| `risk_register` | Single points of failure + mitigations |
| `portfolio_health` | ASHP delivery delayed — what's degraded? |
| `nhcf_compliance` | Does this meet NHCF minimum requirements? |
| `execution_plan` | Commissioning failed — rollback sequence? |
| `summary` | Overall program metrics |
| `cost_effectiveness` | $/tCO2e, $/unit, $/m² per building |
| `schedule_duration` | CPM forward pass — 131 weeks total |
| `dependency_chain` | Full predecessor trace to closeout |
| `toon` | Token-efficient export for LLM consumption |
| `viz` | Pre-computed visualization data (D3.js) |

```bash
cue eval ./nhcf/ -e critical_path
cue eval ./nhcf/ -e "impact_rideau_delay"
cue eval ./nhcf/ -e risk_register
cue eval ./nhcf/ -e cost_effectiveness
```

### 2. Greener Homes Platform (`greener-homes/`)

The IT platform that processes residential EnerGuide audits at scale
for Ontario — the system behind the rebate program.

**Platform:** 17 services, 25 edges, 6 deployment layers
**Shape:** data sources → databases → compute → quality → portals

Same graph engine, different domain shape. NHCF is a project
delivery graph (like a Gantt chart). Greener Homes is a service
topology graph (like a network diagram). The vocabulary handles
both.

| Query | What it answers |
|-------|----------------|
| `deployment` | Service startup order after full outage |
| `impact_database_failure` | Audit DB down — 11/17 affected |
| `critical_services` | Highest SLA requirements |
| `risk_register` | Infrastructure single points of failure |
| `platform_health` | HOT2000 engine stuck — what's degraded? |
| `summary` | Platform metrics |
| `service_categories` | Services grouped by @type |
| `rollback_plan` | Compute layer failure — undo sequence |
| `dependency_chain` | Full predecessor trace to auditor-portal |
| `immediate_dependents` | Direct connections to audit-database |
| `toon` | Token-efficient export for LLM consumption |
| `viz` | Pre-computed visualization data (D3.js) |

```bash
cue eval ./greener-homes/ -e deployment
cue eval ./greener-homes/ -e "impact_database_failure"
cue eval ./greener-homes/ -e service_categories
```

## How the Graph Works

Traditional approach: You build a Gantt chart in P6 or MS Project,
manually assign predecessors, then run what-if scenarios one at a
time. The schedule, risk analysis, and impact assessment are
separate artifacts maintained by different people.

Graph approach: You declare the work packages and their
dependencies. Everything else is computed:

```
Declare:  rideau-audit depends_on consultant-procurement
Computed: schedule phase (depth), critical path (dependents count),
          impact cascade (BFS), rollback sequence (reverse topo),
          health propagation (status inheritance)
```

The concepts map directly:

| PM Concept | Graph Equivalent |
|-----------|-----------------|
| Work package | Resource node |
| Predecessor (FS) | `depends_on` edge |
| WBS level | `@type` tags |
| Schedule phase | `_depth` (computed) |
| Float analysis | `_ancestors` chain |
| What-if scenario | `#ImpactQuery` / `#HealthStatus` |
| Risk register | `#SinglePointsOfFailure` |
| CPM forward pass | `#DeploymentPlan` topology sort |

## Ontario / Ottawa Specs

All energy data uses real Ontario values:

| Parameter | Value | Source |
|-----------|-------|--------|
| Climate zone | NECB Zone 6 | NECB 2020 |
| HDD | 4,500 (18C base) | Climate Atlas |
| Grid carbon | 74 gCO2e/kWh | IESO Ontario 2024 |
| Gas carbon | 49.88 kgCO2e/GJ | NRCan |
| Building code | OBC SB-12 (2024) | Ontario Building Code |
| Modelling tools | HOT2000 v11.10, eQUEST 3.65 | NRCan ERS |
| NHCF minimum | 25% energy + 25% GHG | CMHC Repair Stream |

## Graph Metrics

| | NHCF | Greener Homes |
|-|------|---------------|
| Nodes | 18 work packages | 17 services |
| Edges | 27 dependencies | 25 dependencies |
| Layers | 8 schedule phases | 6 deployment layers |
| Pattern | Project delivery | Service topology |
| Root nodes | NHCF agreement | 3 external data sources |
| Leaf nodes | NHCF closeout | 5 terminal services |

## Deploy Visual Explorer to rfam.cc

```bash
# Build and deploy (validates CUE, exports JSON, pushes to rfam.cc)
bash ~/cjlq/deploy.sh
```

Static files are pushed to container 612 (Caddy, `172.20.1.212`) via
tulip, served at `/var/www/rfam.cc/cjlq/`. Caddy routing needs a path
matcher for `/cjlq/*`. See `caddy-generator.cue` in grdn/jrdn.

## Dependencies

This repo imports vocabulary and patterns from
[quicue.ca](https://github.com/mthdn/quicue.ca) via CUE's module
system. The local symlink at `cue.mod/pkg/quicue.ca` provides
resolution — see `cue.mod/module.cue` for the dependency declaration.
