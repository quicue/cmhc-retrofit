#!/usr/bin/env bash
# Build and deploy CJLQ explorer to rfam.cc
#
# Usage: bash ~/cjlq/deploy.sh
#
# Steps:
#   1. Validates CUE schemas (nhcf + greener-homes)
#   2. Exports graph JSON
#   3. Pushes static files to container 612 via tulip
#
# Prerequisites: SSH access to tulip (172.20.1.10)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build (validates + exports JSON)
bash "${SCRIPT_DIR}/build.sh"

# Deploy to container 612 (Caddy) on tulip
echo ""
echo "Deploying to rfam.cc/cjlq/..."
for f in index.html briefing.html nhcf.json greener-homes.json nhcf-summary.json greener-homes-summary.json; do
    tmp="/tmp/cjlq_${f}"
    ssh tulip "cat > ${tmp}" < "${SCRIPT_DIR}/${f}"
    ssh tulip "pct push 612 ${tmp} /var/www/rfam.cc/cjlq/${f} && rm ${tmp}"
    echo "  ${f} deployed"
done

echo ""
echo "Live at https://rfam.cc/cjlq/"
echo "  Briefing:      https://rfam.cc/cjlq/briefing.html"
echo "  NHCF:          https://rfam.cc/cjlq/#nhcf"
echo "  Greener Homes: https://rfam.cc/cjlq/#greener-homes"
