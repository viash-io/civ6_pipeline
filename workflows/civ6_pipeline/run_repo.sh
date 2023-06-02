#!/bin/bash

export NXF_VER=22.04.5

nextflow drop https://github.com/viash-io/civ6_pipeline.git

nextflow \
  run https://github.com/viash-io/civ6_pipeline.git \
  -r main_build \
  -main-script workflows/civ6_pipeline/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -with-docker \
  -resume
