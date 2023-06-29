#!/bin/bash

if [ -f "$par_output" ]; then
  rm "$par_output"
fi

extra_args=()

# generate includes arguments
IFS=':'
for var in $par_includes; do
  unset IFS
  extra_args+=( --includes "$var" )
done

if [ "$par_include_imhex_patterns" == "true" ]; then
  extra_args+=( --includes "/opt/ImHex-Patterns/includes/" )
fi

# run command
plcli format \
  --input "$par_input" \
  --pattern "$par_pattern" \
  --output "$par_output" \
  ${par_format:+--format $par_format} \
  "${extra_args[@]}" \
  --verbose
