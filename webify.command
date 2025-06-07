#!/bin/bash
cd "$(dirname "$0")"
set -e

# === 1. Backup current folder (optional but recommended) ===
cp -r . ../vault-backup-$(date +%Y%m%d%H%M%S)

# === 2. Function to normalize accents and replace question marks ===
normalize_name() {
  echo "$1" | \
  sed -e 's/[éèêë]/e/g' \
      -e 's/[àâä]/a/g' \
      -e 's/[îï]/i/g' \
      -e 's/[ôö]/o/g' \
      -e 's/[ùûü]/u/g' \
      -e 's/ÿ/y/g' \
      -e 's/ç/c/g' \
      -e 's/?/_/g'
}


export -f normalize_name

# === 3. Only process these folders ===
folders=("000-zettelkasten" "100-half-baked-notes" "200-reference-notes" "300-tag-notes")

> rename_map.txt  # Clear or create mapping file

for folder in "${folders[@]}"; do
  if [ -d "$folder" ]; then
    # Rename files and folders with special characters, ignore hidden files/folders
    find "$folder" -depth \( ! -name ".*" \) -name "*[?àâäéèêëîïôöùûüÿç]*" | while IFS= read -r file; do
      # Skip hidden files/folders
      [[ "$(basename "$file")" =~ ^\. ]] && continue
      dir=$(dirname "$file")
      base=$(basename "$file")
      newbase=$(normalize_name "$base")
      if [[ "$base" != "$newbase" ]]; then
        mv "$file" "$dir/$newbase"
        echo "$base|$newbase" >> rename_map.txt
        echo "Renamed: $file -> $dir/$newbase"
      fi
    done
  fi
done

# === 4. Replace special characters in all HTML files in the specified folders ===
for folder in "${folders[@]}"; do
  if [ -d "$folder" ]; then
    find "$folder" -type f \( ! -name ".*" \) -name "*.html" -exec sed -i '' \
      -e 's/é/e/g' \
      -e 's/è/e/g' \
      -e 's/ê/e/g' \
      -e 's/ë/e/g' \
      -e 's/à/a/g' \
      -e 's/â/a/g' \
      -e 's/ä/a/g' \
      -e 's/î/i/g' \
      -e 's/ï/i/g' \
      -e 's/ô/o/g' \
      -e 's/ö/o/g' \
      -e 's/ù/u/g' \
      -e 's/û/u/g' \
      -e 's/ü/u/g' \
      -e 's/ÿ/y/g' \
      -e 's/ç/c/g' \
      -e 's/?/_/g' \
      {} +
  fi
done

# === 5. Update ONLY the specified JSON files ===
for jsonfile in lib/metadata.json lib/search-index.json; do
  if [[ -f "$jsonfile" ]]; then
    while IFS="|" read -r old new; do
      # Escape special characters for sed
      old_escaped=$(printf '%s' "$old" | sed 's/[]\/$*.^[]/\\&/g')
      new_escaped=$(printf '%s' "$new" | sed 's/[&/\]/\\&/g')
      sed -i '' "s/$old_escaped/$new_escaped/g" "$jsonfile"
    done < rename_map.txt
    echo "Updated $jsonfile"
  fi
done

echo "All done! Backup created, files/folders renamed, HTML and JSON updated."
