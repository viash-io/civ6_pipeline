#!/bin/bash

node /home/node/node_modules/civ6-save-parser/index.js "$par_input" --simple > "$par_output"

# Poor man's log information written to the log file
echo "## Processing $par_input" > $par_log
echo "" >> $par_log
date >> $par_log
echo "" >> $par_log
echo "First 5 lines from \`$par_output:\`" >> $par_log
echo "" >> $par_log
echo "\`\`\`" >> $par_log
head -5 $par_output >> $par_log
echo "\`\`\`" >> $par_log
