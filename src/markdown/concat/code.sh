#!/bin/bash

inputfiles="$(echo $par_input | tr ':' ' ')"
echo $par_header > headerfile.md
pandoc headerfile.md $inputfiles -t markdown >> $par_output
