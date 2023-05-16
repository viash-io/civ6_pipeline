#!/bin/bash

## VIASH START
meta_resources_dir="data"
meta_executable="target/docker/civ6_save_renderer/parse_header/parse_header"
## VIASH END

input_path="${meta_resources_dir}/AutoSave_0158.Civ6Save"
output_path="output.yaml"

# Run executable
echo '>>> Run executable'
"$meta_executable" --input "$input_path" --output "$output_path"

# Check whether output file exists
echo '>>> Check whether output file exists'
if [ ! -f "$output_path" ]; then
  echo "Output file was not found"
  exit 1
fi

# Output content
if [[ `yq .GAME_SPEED $output_path` != "GAMESPEED_ONLINE" ]]; then
  echo Incorrect GAME_SPEED
  exit 1
fi
if [[ `yq .MAP_SIZE $output_path` != "MAPSIZE_STANDARD" ]]; then
  echo Incorrect MAP_SIZE
  exit 1
fi
if [[ `yq .GAME_TURN $output_path` != "158" ]]; then
  echo Incorrect GAME_TURN
  exit 1
fi
if [[ `yq '.ACTORS[0].ACTOR_NAME' $output_path` != "CIVILIZATION_FREE_CITIES" ]]; then
  echo Incorrect ACTOR_NAME
  exit 1
fi
if [[ `yq '.ACTORS[0].ACTOR_TYPE' $output_path` != "CIVILIZATION_LEVEL_FREE_CITIES" ]]; then
  echo Incorrect ACTOR_TYPE
  exit 1
fi
if [[ `yq '.CIVS[0].ACTOR_NAME' $output_path` != "CIVILIZATION_GERMANY" ]]; then
  echo Incorrect ACTOR_NAME
  exit 1
fi
if [[ `yq '.CIVS[0].ACTOR_TYPE' $output_path` != "CIVILIZATION_LEVEL_FULL_CIV" ]]; then
  echo Incorrect ACTOR_TYPE
  exit 1
fi

echo '>>> All tests succeeded!'
exit 0