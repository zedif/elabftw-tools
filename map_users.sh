#!/bin/bash

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

cp migration.eln "$OLDPWD/$(basename "$2" .eln)-migration.eln"
