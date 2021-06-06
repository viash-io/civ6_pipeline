library(tidyverse)
library(cowplot)

source(paste0(resources_dir, "/helper.R"))

# par <- list(
#   yaml = "/home/rcannood/workspace/di/viash_workshop_1/data.yaml",
#   tsv = "/home/rcannood/workspace/di/viash_workshop_1/data.tsv"
# )

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
