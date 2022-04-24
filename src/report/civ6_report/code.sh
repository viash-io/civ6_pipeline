#!/bin/bash

echo ">> Creating output dir if it does not exist yet"
mkdir -p $par_report

echo ">> Copy config file, docs template and docs sources to report dir"
cp $resources_dir/mkdocs.yml $par_report
cp -r $par_input $par_report
cp -r $resources_dir/docs/* $par_report/docs

echo ">> Now run mkdocs"
cd $par_report
mkdocs build

echo ">> Build ready, find the output under site/"
