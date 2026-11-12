# #!/usr/bin/env bash
# # Copies the current Learner Lab credentials into the GitHub repo secrets.
# # Lab credentials expire every session (~4 hours), so run this each time you
# # click "Start Lab" and paste the new credentials into ~/.aws/credentials.
# #
# # Needs: GitHub CLI (`gh auth login` once), run from inside the repo.
# # Usage: ./.github/scripts/refresh-gh-secrets.sh [aws-profile]   (default: default)
# set -euo pipefail

# PROFILE="${1:-default}"
# CREDS="${AWS_SHARED_CREDENTIALS_FILE:-$HOME/.aws/credentials}"

# get() {
#   awk -v section="[$PROFILE]" -v key="$1" '
#     $0 == section { inside = 1; next }
#     /^\[/        { inside = 0 }
#     inside {
#       split($0, kv, "=")
#       k = kv[1]; gsub(/[ \t]/, "", k)
#       if (k == key) { v = substr($0, index($0, "=") + 1); gsub(/^[ \t]+|[ \t\r]+$/, "", v); print v; exit }
#     }' "$CREDS"
# }

# KEY_ID=$(get aws_access_key_id)
# SECRET=$(get aws_secret_access_key)
# TOKEN=$(get aws_session_token)

# if [ -z "$KEY_ID" ] || [ -z "$SECRET" ] || [ -z "$TOKEN" ]; then
#   echo "Missing credentials in [$PROFILE] of $CREDS." >&2
#   echo "In Learner Lab: AWS Details -> AWS CLI: Show, and paste the whole block there." >&2
#   exit 1
# fi

# echo "==> Checking the credentials work"
# AWS_PROFILE="$PROFILE" aws sts get-caller-identity --query Arn --output text

# echo "==> Updating repo secrets"
# printf '%s' "$KEY_ID"  | gh secret set AWS_ACCESS_KEY_ID
# printf '%s' "$SECRET"  | gh secret set AWS_SECRET_ACCESS_KEY
# printf '%s' "$TOKEN"   | gh secret set AWS_SESSION_TOKEN

# echo "Done. Workflows can use AWS until this lab session ends."
