#!/bin/bash

inputfiles="$(echo $par_input | tr ':' ' ')"

pandoc $inputfiles -t markdown >> $par_output
