#!/bin/bash

mkdir -p "$par_docs"
inputfiles=$(echo "$par_input" | tr ":" "\n")

for f in $inputfiles; do
  echo "Copying $f to $par_docs"
  if [ -d $f ]; then
    cp -r "$f" "$par_docs/"
  else
    cp "$f" "$par_docs/"
  fi
done

