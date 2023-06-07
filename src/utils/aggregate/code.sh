#!/bin/bash

inputfiles=$(echo "$par_input" | tr ":" "\n")

for f in $inputfiles; do
  echo "Aggregate $f into $par_output"
  cat $f >> $par_output
done
