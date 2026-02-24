#!/usr/bin/env bash
set -euo pipefail

DEPLOYMENT_PATH="${1:?Usage: compute-hash.sh <deployment-path>}"

(cd "${DEPLOYMENT_PATH}" && find images context \
    -type f \
    -not -path "*/nginx/ssl/*" \
    -not -path "*/nginx/auth/*" \
    -print0 | sort -z | xargs -0 md5sum | md5sum | cut -d' ' -f1)
