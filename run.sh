#!/bin/bash

export NXF_VER=21.04.1

nextflow \
  run . \
  -main-script main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -resume
