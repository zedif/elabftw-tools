#!/bin/bash
# Maps email addresses of users in metadata of ELN file.
#
# Usage: map_users mapping-file eln-file [out-file]
#
# mapping-file   CSV file with two columns:
#                old email address, new email address
# eln-file       original ELN file
# out-file       modified ELN file
#                If not specified, the suffix "-mapped" will be
#                appended to the original ELN file name.

TMP_DIR=$(mktemp -d)

cp "$2" $TMP_DIR/migration.eln
cp "$1" $TMP_DIR/
cd $TMP_DIR

unzip migration.eln "*/ro-crate-metadata.json"
cp */ro-crate-metadata.json ro-crate-metadata.json.bak

IFS=''
while read -r line || [ -n "$line" ] ; do
  old_email=$(echo "$line" | cut -d, -f1)
  new_email=$(echo "$line" | cut -d, -f2)
  sed -i "s/\(\"email\":\"\)$old_email\"/\1$new_email\"/" \
      */ro-crate-metadata.json
done < "$1"

zip --freshen migration.eln */ro-crate-metadata.json

cp migration.eln "$OLDPWD/${3:-$(basename "$2" .eln)-mapped.eln}"
