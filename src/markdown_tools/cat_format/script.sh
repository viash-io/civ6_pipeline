#!/bin/bash

echo ""
echo "\`$par_input\`:"
echo ""

echo '```'"$par_format"
if [ "$par_cut" == "true" ]; then
  head "$par_input"
  echo "... (cut) ..."
else
  cat "$par_input"
  echo ""
fi
echo '```'
