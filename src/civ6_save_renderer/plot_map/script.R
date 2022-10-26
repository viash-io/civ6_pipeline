library(tidyverse)
library(cowplot)

## VIASH START
par <- list(
  "yaml" = "header.yaml",
  "tsv" = "map.tsv",
  "output" = "output.pdf"
)
meta <- list(
  "resources_dir" = "src/civ6_save_renderer/plot_map"
)
## VIASH END

source(paste0(meta$resources_dir, "/helper.R"))

# read data
game_data <- read_header(par$yaml)
map_data <- read_map(par$tsv)

# make visualisation
g <- make_map_plot(game_data, map_data)

# save map to file
gleg <- cowplot::get_legend(g)
gnoleg <- g + theme(legend.position = "none")
gout <- cowplot::plot_grid(gnoleg, gleg, rel_widths = c(8, 1))
ggsave(par$output, gout, width = 24, height = 13)
