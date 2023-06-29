#!/bin/bash

set -e

output_prefix=data/saves/000085
# output_prefix=data/AutoSave_0162
# output_prefix=data/saves/testmap_v0.4

viash run src/civ6_save_renderer/parse_header/config.vsh.yaml -- \
  --input ${output_prefix}.Civ6Save \
  --output ${output_prefix}_header.yaml

# viash run src/civ6_save_renderer/dump_decompressed/config.vsh.yaml -- \
#   --input ${output_prefix}.Civ6Save \
#   --output ${output_prefix}_map.bin

viash run src/civ6_save_renderer/parse_map/config.vsh.yaml -- \
  --input ${output_prefix}.Civ6Save \
  --output ${output_prefix}_map.tsv

viash run src/civ6_save_renderer/plot_map/config.vsh.yaml -- \
  --yaml ${output_prefix}_header.yaml \
  --tsv ${output_prefix}_map.tsv \
  --output ${output_prefix}_map.pdf

viash run src/civ6_save_renderer/parse_imhex/config.vsh.yaml -- \
  --input ${output_prefix}_map.bin \
  --output ${output_prefix}_map.json \
  --pattern ../civ6save_analysis/main.hex \
  --includes ../civ6save_analysis/patterns/ \
  --include_imhex_patterns