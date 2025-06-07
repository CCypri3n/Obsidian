#!/bin/bash
cd "$(dirname "$0")"
set -e

find . -type f -name "*.html" | while IFS= read -r HTML_FILE; do
  TMP_FILE="${HTML_FILE}.tmp"
  perl -MFile::Spec -MCwd -0777 -pe '
    my $base_dir = getcwd();
    # Match: <a ... href="SOMEFILE.html[#fragment]" ...>text</a>
    s{<a\s+([^>]*?)href="([^"]+\.html(?:#[^"]*)?)"([^>]*)>(.*?)</a>}{
      my ($pre, $href, $post, $text) = ($1, $2, $3, $4);
      # Skip external links
      if ($href =~ m{^(?:https?:)?//}) {
        qq{<a $pre href="$href"$post>$text</a>};
      } else {
        # Remove #fragment for file existence check
        my $check = $href;
        $check =~ s/#.*$//;
        # Remove leading ./ or ../ for filesystem check
        $check =~ s#^(\./)+##;
        $check =~ s#^(\.\./)+##;
        my $file_path = File::Spec->rel2abs($check, $base_dir);
        if (-e $file_path) {
          qq{<a $pre href="$href"$post>$text</a>};
        } else {
          $text;
        }
      }
    }eg;
  ' < "$HTML_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$HTML_FILE"
  echo "Checked links in $HTML_FILE"
done

echo "All HTML files have been checked for broken .html links."
