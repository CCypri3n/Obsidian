#!/bin/bash
cd "$(dirname "$0")"
set -e

FOLDERS="000-zettelkasten 100-half-baked-notes 200-reference-notes 300-tag-notes"

# Loop over all HTML files
find . -type f -name "*.html" | while IFS= read -r HTML_FILE; do
  TMP_FILE="${HTML_FILE}.tmp"
  perl -MFile::Spec -MCwd -E '
    my @folders = @ARGV;
    my $base_dir = getcwd();
    while (<STDIN>) {
      my $line = $_;
      foreach my $folder (@folders) {
        # Regex: match folder/basename?.md[#fragment]
        while ($line =~ m{($folder)/([^/?"\x27]+)\?*\.md(#\S+)?}g) {
          my ($f, $base, $frag) = ($1, $2, $3 // "");
          my $subfolder = File::Spec->catdir($base_dir, $f, $base);
          my $newurl = -d $subfolder
            ? "$f/$base/$base.html$frag"
            : "$f/$base.html$frag";
          $line =~ s{\Q$f/$base\E\?*\.md\Q$frag\E}{$newurl};
        }
      }
      print $line;
    }
  ' $FOLDERS < "$HTML_FILE" > "$TMP_FILE"
  mv "$TMP_FILE" "$HTML_FILE"
  echo "Fixed links in $HTML_FILE"
done

echo "All HTML files have been updated."
