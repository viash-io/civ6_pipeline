
# Civ6 post-game summary POC

This is a toy dataset which uses savefiles from a game called
Civilization VI and generates a post-game video of the in-game tile
ownership over time.

You can see the general workflow for generating a postgame replay video
in the diagram below.

![](docs/images/workflow.png)

## Requirements

Install Viash and Nextflow in a directory that are on the `$PATH`,
e.g. `$HOME/bin`.

``` bash
mkdir $HOME/bin
curl -fsSL http://dl.viash.io | bash; mv viash $HOME/bin
curl -s https://get.nextflow.io | bash; mv nextflow $HOME/bin
```

Make sure that Viash and Nextflow are on the \$PATH by checking whether
the following commands work:

``` bash
viash -v
nextflow -v
```

## Run a release build of the pipeline

``` sh
NXF_VER=22.04.5 nextflow \
  run viash-io/civ6_pipeline \
  -r main_build \
  -main-script workflows/civ6_pipeline/main.nf \
  --input "data/*.Civ6Save" \
  --publishDir "output" \
  -resume \
  -with-docker
```

<!-- todo: use an actual release -->

## Run the development build of the pipeline

First build components for the pipeline. Building the docker containers
from scratch will take a while.

``` bash
viash ns build --parallel --setup cb
```

Generate the post-game summary movie (stored at `output/output.webm`) by
running:

``` bash
workflows/civ6_pipeline/run.sh
```

## Known issues

Note that this pipeline may not extend its support beyond the specific
assets used in [this
video](https://www.youtube.com/watch?v=wxw3T9589-c). Rendering other
world leaders, wonders, and additional elements may require further
development.

## Background on Civilization

Civilization is a series of six video strategy games where players
oversee the development of a civilization, starting from the dawn of
civilizations until present times. Not only is the series famous for
having defined a lot of the game mechanics in the 4X genre (eXplore,
eXpand, eXploit, and eXterminate), it is also frequently associated with
the “One More Turn Syndrome”.

![Comic by Mart Virkus,
https://arcaderage.co/2016/10/18/civilization-vi/](docs/images/mart_virkus_every_civilization_game_ever.jpg)

### Post-game replay map

Multiplayer games can take a few hours to finish – anywhere between 2 to
10 hours, depending on who you’re playing with. That’s why a perfect way
of closing a session of Civilization V is by being able to watch a
‘postgame map replay’ of which owner owned which time at any given point
in time.

<div>

[![](docs/images/civ5_victory_.png)](docs/images/civ5_victory_.webm)

</div>

However, for whatever reason, this feature did not make it in
Civilization VI. This made a lot of people very angry and been widely
regarded as a bad move. <!-- quoting Douglas Adams here -->

![](docs/images/civ6_rant_.png)

### Rendering post-game replay maps

At Data Intuitive, we’re all about alleviating people’s suffering, so we
developed a few scripts for rendering a postgame video for Civilization
VI using open-source tools. It works by letting the game automatically
creates saves for every turn of the game (called ‘autosaves’). An
autosave contains all the information to resume the game from that point
in time. Since the information that we need is stored in a format, we
need scripts to: 1. extract the information from the binary format (in
JavaScript), 2. generate a map visualisation (in R), 3. convert all the
visualisations into a video (with ImageMagick and ffmpeg).

## Inspiration

- [pydt/civ6-save-parser](https://github.com/pydt/civ6-save-parser)

- [lucienmaloney/civ6save-editing](https://github.com/lucienmaloney/civ6save-editing)
