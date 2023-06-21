#!/bin/bash

## VIASH START
meta_resources_dir="data"
meta_executable="target/docker/civ6_save_renderer/parse_map/parse_map"
## VIASH END

input_path="${meta_resources_dir}/AutoSave_0162.Civ6Save"
output_path="output.tsv"

# Run executable
echo '>>> Run executable'
"$meta_executable" --input "$input_path" --output "$output_path"

# Check whether output file exists
echo '>>> Check whether output file exists'
if [ ! -f "$output_path" ]; then
  echo "Output file was not found"
  exit 1
fi

# Output content
if ! grep -q "hex_location" "$output_path"; then
  echo Could not find header
  exit 1
fi
if ! grep -q "592796099" "$output_path"; then
  echo Could not find marsh feature
  exit 1
fi

echo '>>> All tests succeeded!'
exit 0