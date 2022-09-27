#!/bin/bash

export NXF_VER=21.04.1

bin/nextflow \
  run . \
  -main-script workflows/run/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -resume
