#!/usr/bin/env bash
# Build CJLQ explorer — exports graph data from CUE and prepares static files
#
# Usage: bash ~/cjlq/build.sh
#
# Prerequisites: cue v0.15.3, quicue.ca symlinked at cue.mod/pkg/quicue.ca

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== CJLQ Explorer Build ==="

# Validate first
echo "Validating NHCF..."
cue vet ./nhcf/

echo "Validating Greener Homes..."
cue vet ./greener-homes/

# Export viz data (pre-computed nodes, edges, topology, criticality, SPOF, metrics + raw resources)
echo "Exporting NHCF viz..."
cue export ./nhcf/ -e viz --out json > "${SCRIPT_DIR}/nhcf.json"

echo "Exporting Greener Homes viz..."
cue export ./greener-homes/ -e viz --out json > "${SCRIPT_DIR}/greener-homes.json"

# Export query results for detail panels
echo "Exporting NHCF summary..."
cue export ./nhcf/ -e summary --out json > "${SCRIPT_DIR}/nhcf-summary.json"

echo "Exporting Greener Homes summary..."
cue export ./greener-homes/ -e summary --out json > "${SCRIPT_DIR}/greener-homes-summary.json"

echo ""
echo "Build complete. Files:"
ls -lh "${SCRIPT_DIR}"/*.json "${SCRIPT_DIR}"/index.html "${SCRIPT_DIR}"/briefing.html 2>/dev/null || true
echo ""
echo "Preview: python3 -m http.server -d ${SCRIPT_DIR} 8082"
echo "Deploy:  bash ${SCRIPT_DIR}/deploy.sh"
