#!/bin/bash
cd "$(dirname "$0")"
set -e

# Process all HTML files in this directory and subdirectories
find . -type f -name "*.html" | while IFS= read -r HTML_FILE; do
  TMP_FILE="${HTML_FILE}.tmp"
  perl -MFile::Spec -MCwd -pe '
    my $base_dir = getcwd();
    # Find all <a href="...html"...>...</a>
    s{<a\s+([^>]*?)href="([^"]+\.html)(#[^"]*)?"([^>]*)>(.*?)</a>}{
      my ($pre, $href, $frag, $post, $text) = ($1, $2, $3 // "", $4, $5);
      # Ignore absolute URLs (http/https)
      if ($href =~ m{^(?:https?:)?//}) {
        qq{<a $pre href="$href$frag"$post>$text</a>};
      } else {
        # Remove leading ./ or ../ for filesystem check
        my $check = $href;
        $check =~ s#^(\./)+##;
        $check =~ s#^(\.\./)+##;
        my $file_path = File::Spec->rel2abs($check, $base_dir);
        if (-e $file_path) {
          qq{<a $pre href="$href$frag"$post>$text</a>};
        } else {
          $text;
        }
      }
    }egx;
  ' < "$HTML_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$HTML_FILE"
  echo "Checked links in $HTML_FILE"
done

echo "All HTML files have been checked for broken links."
