#!/bin/bash

mkdir -p "$par_docs"
mkdir -p "$par_docs/resources"

inputfiles=$(echo "$par_input" | tr ":" "\n")
resourcedirs=$(echo "$par_resources" | tr ":" "\n")

for f in $inputfiles; do
  echo "Copying $f to $par_docs"
  if [ -d $f ]; then
    cp -r "$f" "$par_docs/"
  else
    cp "$f" "$par_docs/"
  fi
done

for d in $resourcedirs; do
  echo "Copying $d/* to $par_docs/resources"
  cp -r $d/* $par_docs/resources/
done
