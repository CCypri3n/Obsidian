#!/bin/sh
cd "$(dirname "$0")"
git add .
git commit -m "Automated export $(date '+%Y-%m-%d %H:%M')"
git push

