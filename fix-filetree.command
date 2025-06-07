#!/bin/bash
cd "$(dirname "$0")"
set -e

HTML_FILE="lib/html/file-tree.html"
TMP_FILE="lib/html/file-tree.tmp"

FOLDERS="000-zettelkasten 100-half-baked-notes 200-reference-notes 300-tag-notes"

perl -MFile::Spec -MCwd -E '
  my @folders = @ARGV;
  my $base_dir = getcwd();
  while (<STDIN>) {
    my $line = $_;
    foreach my $folder (@folders) {
      while ($line =~ m{($folder)/([^/?"\x27]+)\?*\.md}g) {
        my ($f, $base) = ($1, $2);
        my $subfolder = File::Spec->catdir($base_dir, $f, $base);
        my $newurl = -d $subfolder
          ? "$f/$base/$base.html"
          : "$f/$base.html";
        $line =~ s{\Q$f/$base\E\?*\.md}{$newurl};
      }
    }
    print $line;
  }
' $FOLDERS < "$HTML_FILE" > "$TMP_FILE"

mv "$TMP_FILE" "$HTML_FILE"

echo "URLs in $HTML_FILE have been updated."
