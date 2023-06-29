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

if [ "$par_include_std" == "true" ]; then
  extra_args+=( --includes "/opt/ImHex-Patterns/includes/std/" )
fi
if [ "$par_include_hex" == "true" ]; then
  extra_args+=( --includes "/opt/ImHex-Patterns/includes/hex/" )
fi
if [ "$par_include_type" == "true" ]; then
  extra_args+=( --includes "/opt/ImHex-Patterns/includes/type/" )
fi

# run command
plcli format \
  --input "$par_input" \
  --pattern "$par_pattern" \
  --output "$par_output" \
  ${par_format:+--format $par_format} \
  "${extra_args[@]}" \
  --verbose
