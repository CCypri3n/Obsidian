#!/bin/sh
cd "$(dirname "$0")"

"$(dirname "$0")/fix-filetree.command"
"$(dirname "$0")/repair-broken-markdownurls.command"
"$(dirname "$0")/remove-broken-hyperlinks.command"
# Export the current state of the repository

git add .
git commit -m "Automated export $(date '+%Y-%m-%d %H:%M')"
git push

