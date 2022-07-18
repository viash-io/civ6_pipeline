#!/bin/bash

# Poor man's log information written to the log file
echo "## Validating $par_input" > $par_log

# Pass input to output
cp $par_input $par_output

# branch off for reporting purposes
mkdir $par_resources
cp $par_input $par_resources/$par_output

echo "![](resources/$par_output)" >> $par_log
echo "" >> $par_log
