#!/bin/bash

if [ -f "$par_output" ]; then
  rm "$par_output"
fi
plcli format \
  --input "$par_input" \
  --pattern "$par_pattern" \
  --output "$par_output" \
  ${par_includes:+--includes $par_includes} \
  ${par_format:+--format $par_format}