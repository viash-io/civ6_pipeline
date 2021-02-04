#!/bin/bash

# render movie
inputs=`echo $par_input | sed 's#:# -i #g'`
ffmpeg -framerate $par_framerate -f image2 -i $inputs -c:v libvpx-vp9 -pix_fmt yuva420p -y $par_output
