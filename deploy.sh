#!/usr/bin/env bash
# Build and deploy CMHC Retrofit explorer to quicue.ca
#
# Usage: bash ~/cmhc-retrofit/deploy.sh
#
# Steps:
#   1. Validates CUE schemas (nhcf + greener-homes)
#   2. Exports graph JSON
#   3. Pushes static files to the web server
#
# Environment:
#   DEPLOY_HOST    — SSH host for deployment (required)
#   DEPLOY_CT      — container ID on the deploy host (required)
#   DEPLOY_WEBROOT — web root path (default: /var/www/quicue.ca/cmhc-retrofit)

set -euo pipefail

: "${DEPLOY_HOST:?Set DEPLOY_HOST to the SSH hostname}"
: "${DEPLOY_CT:?Set DEPLOY_CT to the container ID}"
DEPLOY_WEBROOT="${DEPLOY_WEBROOT:-/var/www/quicue.ca/cmhc-retrofit}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Build (validates + exports JSON)
bash "${SCRIPT_DIR}/build.sh"

# Deploy static files
echo ""
echo "Deploying to ${DEPLOY_HOST} ct${DEPLOY_CT}:${DEPLOY_WEBROOT}..."
for f in index.html briefing.html nhcf.json greener-homes.json nhcf-summary.json greener-homes-summary.json; do
    tmp="/tmp/cmhc-retrofit_${f}"
    ssh "${DEPLOY_HOST}" "cat > ${tmp}" < "${SCRIPT_DIR}/${f}"
    ssh "${DEPLOY_HOST}" "pct push ${DEPLOY_CT} ${tmp} ${DEPLOY_WEBROOT}/${f} && rm ${tmp}"
    echo "  ${f} deployed"
done

echo ""
echo "Live at https://cmhc-retrofit.quicue.ca/"
echo "  Briefing:      https://cmhc-retrofit.quicue.ca/briefing.html"
echo "  NHCF:          https://cmhc-retrofit.quicue.ca/#nhcf"
echo "  Greener Homes: https://cmhc-retrofit.quicue.ca/#greener-homes"
