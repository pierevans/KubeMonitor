# #!/usr/bin/env bash
# # Prints a JSON array of the components from .github/components.json whose
# # folder contains the given marker file, e.g.:
# #   detect-components.sh package.json  ->  [{"name":"web","path":"frontend/dashboard"}]
# # Used by CI (marker: package.json) and Deploy (marker: Dockerfile) so jobs
# # only run for parts of the app that exist yet.
# set -euo pipefail

# MARKER="${1:?usage: detect-components.sh <marker-file>}"
# CONFIG="${COMPONENTS_FILE:-.github/components.json}"

# jq -c --arg marker "$MARKER" '.[]' "$CONFIG" | while read -r comp; do
#   path=$(jq -r '.path' <<<"$comp")
#   if [ -f "$path/$MARKER" ]; then
#     echo "$comp"
#   fi
# done | jq -cs '.'
