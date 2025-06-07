#!/bin/sh
cd "$(dirname "$0")"

"$(dirname "$0")/webify.command"
"$(dirname "$0")/fix-all-links.command"
# Export the current state of the repository

git add .
git commit -m "Automated export $(date '+%Y-%m-%d %H:%M')"
git push

