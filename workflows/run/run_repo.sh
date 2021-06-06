#!/bin/bash

export NXF_VER=21.04.1

nextflow drop https://github.com/viash-io/civ6_pipeline.git

nextflow \
  run https://github.com/viash-io/civ6_pipeline.git \
  -r main_build \
  -main-script workflows/run/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -resume
