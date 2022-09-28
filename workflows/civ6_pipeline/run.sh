#!/bin/bash

export NXF_VER=22.04.5

bin/nextflow \
  run . \
  -main-script workflows/civ6_pipeline/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -with-docker \
  -resume
