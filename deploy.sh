#!/usr/bin/env bash
# Build and deploy CMHC Retrofit explorer to quicue.ca
#
# Usage: bash ~/cmhc-retrofit/deploy.sh
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
echo "Deploying to quicue.ca/cmhc-retrofit/..."
for f in index.html briefing.html nhcf.json greener-homes.json nhcf-summary.json greener-homes-summary.json; do
    tmp="/tmp/cmhc-retrofit_${f}"
    ssh tulip "cat > ${tmp}" < "${SCRIPT_DIR}/${f}"
    ssh tulip "pct push 612 ${tmp} /var/www/quicue.ca/cmhc-retrofit/${f} && rm ${tmp}"
    echo "  ${f} deployed"
done

echo ""
echo "Live at https://quicue.ca/cmhc-retrofit/"
echo "  Briefing:      https://quicue.ca/cmhc-retrofit/briefing.html"
echo "  NHCF:          https://quicue.ca/cmhc-retrofit/#nhcf"
echo "  Greener Homes: https://quicue.ca/cmhc-retrofit/#greener-homes"
