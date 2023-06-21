#!/bin/bash

viash run src/civ6_save_renderer/parse_header/config.vsh.yaml -- \
  --input data/AutoSave_0162.Civ6Save \
  --output data/AutoSave_0162_header.yaml

viash run src/civ6_save_renderer/parse_map/config.vsh.yaml -- \
  --input data/AutoSave_0162.Civ6Save \
  --output data/AutoSave_0162_map.tsv

viash run src/civ6_save_renderer/plot_map/config.vsh.yaml -- \
  --yaml data/AutoSave_0162_header.yaml \
  --tsv data/AutoSave_0162_map.tsv \
  --output data/AutoSave_0162_map.pdf