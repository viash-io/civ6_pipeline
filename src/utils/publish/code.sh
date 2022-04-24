#!/bin/bash

inputfiles=$(echo $par_input | tr ":" "\n")

if [[ ! `dirname "$par_output"` == "." ]]; then
  dirs=`dirname "$par_output"`
  f=`basename "$par_output"`
  echo "The output is in a subdirectory, create it: $dirs"
  echo "The filename is $f"
  mkdir -p $dirs
else
  echo "The output is a file: $par_output"
  f=$par_output
fi

for f in $inputfiles; do
  echo "Copying $f to $par_output"
  cp -r "$f" "$par_output"
done
chmod -R a+rwx *
