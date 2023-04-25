#!/bin/bash

inputs=$(echo $par_input | tr ':' '|')
ffmpeg -framerate $par_framerate -i "concat:$inputs" -c:v libvpx-vp9 -pix_fmt yuva420p -y "$par_output"
