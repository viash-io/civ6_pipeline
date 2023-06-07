#!/bin/bash

echo ">> Creating output dir if it does not exist yet"
mkdir -p $par_output

echo ">> Copy config file, docs template and docs sources to report dir"
cp -r $par_input $par_output

echo ">> Add Quarto config"
cd $par_output

cat > _quarto.yml <<END
project:
  type: website

website:
  title: "Civ6 Report"

format:
  html:
    theme: cosmo
    toc: true
END

echo ">> Run Quarto"
quarto render

echo ">> Build ready, find the output under site/"
