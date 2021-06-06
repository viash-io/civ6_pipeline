#!/bin/bash

export NXF_VER=21.04.1

bin/nextflow \
  run . \
  -main-script workflows/run/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -resume \
  -c workflows/run/nextflow.config # TODO: need to be able to remove this at some point
