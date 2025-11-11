#!/bin/bash
# Checks if an eLabFTW entry's maintext refers to an image that is
# not attached to this entry.
#
# Usage: check_images file {experiment|"experiment template"|resource|"resource template"}
#
# Checks in given ELN file for selected entry type.
# 
# Requires jq <https://jqlang.org/>.

TMP_DIR=$(mktemp -d)
unzip -p "$1" "*/ro-crate-metadata.json" > $TMP_DIR/ro-crate-metadata.json

# Iterate over all entries of given type (genre).
while IFS= read -r element; do
  # Get all attachments of the entry.
  mapfile -t parts < <(echo "$element"| \
                         jq -c 'select(.hasPart != null)|.hasPart.[]."@id"')

  # Lookup references for each attachment:
  # - Attachments are separate file entrys with the @id given in the
  #   hasPart element.
  # - The reference is alternateName field.
  attachments=()
  for p in "${parts[@]}"; do
    attachments+=($(jq -r -c '."@graph".[]|select(."@id" == '"$p"').alternateName' \
                       $TMP_DIR/ro-crate-metadata.json))
  done

  # Check src of each HTML img element in main text of the entry
  # refer to one of the attachments.
  # - Use only reference part of src.
  # - Print missing attachments.
  while IFS= read -r img; do
    if [[ ! "${attachments[*]}" =~ "$img" ]]; then
      echo "$element" | jq -r '."name"'
    fi
  done < <(echo "$element" | jq -r -c  '.text' | \
    grep -oP "<img[^>]*>" | \
    sed 's/.*src=\".*[?;]f=\([^"&]*\)[^>]*>/\1/')
done < <(jq -c '."@graph".[]|select(.genre=="'"$2"'")' \
            $TMP_DIR/ro-crate-metadata.json)
