#!/usr/bin/env bash
set -euo pipefail

# Usage: contrib/new-record.sh "kebab-title" "Status"
# Example: contrib/new-record.sh "deploy-onchain-flow" "Proposed"

TITLE_KEBAB=${1:-}
STATUS=${2:-Accepted}
DATE=$(date +%F)
CONTRIB_DIR="contrib"

if [[ -z "$TITLE_KEBAB" ]]; then
  echo "Usage: contrib/new-record.sh \"kebab-title\" \"Status\"" >&2
  exit 1
fi

# Find next number
NEXT=$(ls -1 "$CONTRIB_DIR" | grep -E '^[0-9]{4}-' | sed 's/-.*//' | sort -n | tail -n1)
if [[ -z "$NEXT" ]]; then
  NEXT=1
else
  NEXT=$((NEXT+1))
fi
NNNN=$(printf "%04d" "$NEXT")
FILENAME="$CONTRIB_DIR/${NNNN}-${TITLE_KEBAB}.md"

cat > "$FILENAME" << 'EOF'
# NNNN: TITLE

Status: STATUS
Date: DATE

## Context

<Background and problem statement>

## Decision

<Key decisions made>

## Implementation

<Files, scripts, modules touched; how it was done>

## Pinned Versions (optional)

- <tool>: <version>

## Validation

<How it was tested; commands or scenarios>

## Commit Structure (one file per commit)

1. <subject> — <file>

## Notes

<Additional considerations>
EOF

# Replace placeholders
sed -i "s/^# NNNN: TITLE/# ${NNNN}: ${TITLE_KEBAB//-/ /}/" "$FILENAME"
sed -i "s/^Status: STATUS/Status: ${STATUS}/" "$FILENAME"
sed -i "s/^Date: DATE/Date: ${DATE}/" "$FILENAME"

echo "Created: $FILENAME"
