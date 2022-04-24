#!/bin/bash

# Poor man's log information written to the log file
echo "# Processing $par_input" > $par_log
echo "" >> $par_log
date >> $par_log
echo "" >> $par_log
echo "stdout output:" >> $par_log
echo "" >> $par_log
echo "\`\`\`" >> $par_log

# actual command
convert "$par_input" -flatten "$par_output" | tee -a $par_log

echo "\`\`\`" >> $par_log
