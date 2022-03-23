# Civ6 post-game summary

This is a toy dataset which uses savefiles from a game called Civilization VI and generates a post-game video of the in-game tile ownership over time.

## Install

Download Nextflow and Viash in `./bin`.

```bash
bin/init
```

## Build
First build components for the pipeline. Building the docker containers from scratch will take a while.

```bash
bin/viash_build
```

## Run
Generate the post-game summary movie (stored at `output/output.webm`) by running:
```bash
workflows/run/run.sh
```