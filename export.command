#!/bin/sh
cd "$(dirname "$0")"

"$(dirname "$0")/webify.command"

git add .
git commit -m "Automated export $(date '+%Y-%m-%d %H:%M')"
git push

