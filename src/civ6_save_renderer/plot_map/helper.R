library(tidyverse)
requireNamespace("ggforce", quietly = TRUE)
requireNamespace("civ6saves", quietly = TRUE)
requireNamespace("bit64", quietly = TRUE)
requireNamespace("yaml", quietly = TRUE)
requireNamespace("ggnewscale", quietly = TRUE)

read_header <- function(yaml_file) {
  game_data <-
    readr::read_lines(yaml_file) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>% # small workaround because the yaml package does not support backticks
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)'(.*)`", "`\\1\\2`", .) %>%
    gsub("`([^']*)`", "'\\1'", .) %>%
    yaml::yaml.load(handlers = list(int = identity))

  # transform some objects to data frames (a table)
  for (nam in c("ACTORS", "CIVS", "MOD_BLOCK_1", "MOD_BLOCK_2", "MOD_BLOCK_3")) {
    game_data[[nam]] <- game_data[[nam]] %>% map_df(data.frame) %>% as_tibble()
  }
  
  game_data
}

read_map <- function(tsv_file) {
  read_tsv(tsv_file, col_types = cols(.default = "c")) %>%
    mutate_at(vars(-starts_with("buffer")), function(x) {
      y <- bit64::as.integer64(x)
      if (max(y, na.rm = TRUE) <= .Machine$integer.max) {
        as.integer(y)
      } else {
        y
      }
    })
}

make_map_plot <- function(game_data, map_data) {
  # get leader info
  owner_ids <- map_data$owner %>% unique() %>% sort()

  # assign colours to civs
  leader_colours <- bind_rows(
    game_data$CIVS %>%
      transmute(owner = row_number() - 1L, leader = LEADER_NAME) %>%
      left_join(civ6saves::leaders, by = "leader") %>%
      rename(leader_inner_colour = leader_outer_colour, leader_outer_colour = leader_inner_colour),
    tibble(
      owner = setdiff(owner_ids, c(seq_len(nrow(game_data$CIVS)) - 1, 62L, 255L))
    ) %>% mutate(
      leader = NA_character_,
      leader_name = paste0("City State ", seq_along(owner)),
      leader_inner_colour = rainbow(length(owner)),
      leader_outer_colour = "#111111"
    ),
    tribble(
      ~owner, ~leader, ~leader_name, ~leader_inner_colour, ~leader_outer_colour,
      62L, "BARBARIAN", "Barbarian", "black", "black",
      255L, "LEADER_FREE_CITIES", "Free Cities", "red", "black"
    )
  )
  owner_outer_palette <- leader_colours %>% select(leader_name, leader_outer_colour) %>% deframe()
  owner_inner_palette <- leader_colours %>% select(leader_name, leader_inner_colour) %>% deframe()

  # fetch static part of the map
  tab_static <- map_data %>%
    civ6saves::add_coordinates() %>%
    left_join(civ6saves::terrains, by = "terrain") %>%
    left_join(civ6saves::features, by = "feature")

  rivers <- civ6saves::get_river_coordinates(tab_static)

  # plot static part of the map
  alpha <- 0.25

  g0 <-
    civ6saves::plot_empty_map(tab_static) +
    ggforce::geom_regon(aes(fill = terrain_name), alpha = alpha) +
    geom_text(aes(label = "^"), tab_static %>% filter(terrain_form == "Hill"), alpha = alpha) +
    geom_text(aes(label = "^"), tab_static %>% filter(terrain_form == "Mountain"), fontface = "bold", alpha = alpha) +
    geom_segment(aes(x = xa, xend = xb, y = ya, yend = yb), colour = civ6saves::feature_palette[["River"]], rivers, size = 1, alpha = alpha) +
    scale_fill_manual(values = civ6saves::terrain_palette) +
    theme(legend.position = "right")

  # plot dynamic part of the map
  tab <- map_data %>%
    civ6saves::add_coordinates() %>%
    left_join(civ6saves::features, by = "feature") %>%
    left_join(civ6saves::improvements, by = "improvement") %>%
    left_join(civ6saves::world_wonders, by = "world_wonder") %>%
    left_join(civ6saves::roads, by = "road") %>%
    left_join(leader_colours %>% select(owner, leader, leader_name), by = "owner") %>%
    mutate(leader_name = factor(leader_name, levels = leader_colours$leader_name))

  civ_borders <- civ6saves::get_border_coordinates(tab)
  road_coords <- civ6saves::get_road_coordinates(tab)

  cities <- tab %>% group_by(owner, city_1) %>% filter(district == min(district)) %>% ungroup()

  players <- game_data$ACTORS %>% filter(ACTOR_TYPE == "CIVILIZATION_LEVEL_FULL_CIV") %>% select(leader = LEADER_NAME) %>% left_join(civ6saves::leaders, by = "leader")

  g <- g0 +
    ggforce::geom_regon(aes(r = civ6saves:::xy_ratio * .9), tab %>% filter(feature_name == "Ice"), fill = civ6saves::feature_palette[["Ice"]], alpha = .4) +
    labs(
      title = paste0("Turn ", game_data$GAME_TURN, " - ", tolower(gsub("MAPSIZE_", "", game_data$SIZE))),
      subtitle = paste0(players$leader_name, collapse = ", "),
      fill = "Terrain"
    )

  if (nrow(road_coords) > 0) {
    g <- g +
      geom_segment(aes(x = xa, xend = xb, y = ya, yend = yb, colour = road_name), road_coords %>% mutate(x0 = xa, y0 = ya), size = 1.5, alpha = .4) +
      scale_colour_manual(values = c("Ancient Road" = "#8e712b", "Railroad" = "darkgray", "Classical Road" = "#a2a2a2", "Industrial Road" = "#6e6e6e", "Modern Road" = "#424242")) +
      labs(colour = "Road")
  }

  if (nrow(tab %>% filter(!is.na(owner))) > 0) {
    g <- g +
      ggnewscale::new_scale_fill() +
      ggnewscale::new_scale_color() +
      ggforce::geom_regon(aes(fill = leader_name), tab %>% filter(!is.na(leader_name)), alpha = .6) +
      geom_segment(aes(x = xa, xend = xb, y = ya, yend = yb, colour = leader_name), civ_borders %>% filter(!is.na(leader_name)), size = 1) +
      geom_point(aes(x = x0, y = y0, colour = leader_name), cities %>% filter(!is.na(leader_name)), size = 3) +
      scale_fill_manual(values = owner_outer_palette) +
      scale_colour_manual(values = owner_inner_palette) +
      labs(colour = "Leader", fill = "Leader")
  }
  
  g
}

