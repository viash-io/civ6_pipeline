## VIASH START
meta <- list(
  resources_dir = "data",
  executable = "target/docker/civ6_save_renderer/plot_map/plot_map"
)
## VIASH END

header_path <- paste0(meta$resources_dir, "/AutoSave_0162_header.yaml")
map_path <- paste0(meta$resources_dir, "/AutoSave_0162_map.tsv")
output_path <- "output.pdf"

# Run executable
cat(">>> Run executable\n")
out <- processx::run(
  meta$executable,
  args = c(
    "--yaml", header_path,
    "--tsv", map_path,
    "--output", output_path
  ),
  error_on_status = FALSE
)

if (out$status > 0) {
  stop(out$stderr)
}

# Check whether output file exists
cat(">>> Check whether output file exists\n")
if (!file.exists(output_path)) {
  stop("Output file was not found")
}

cat(">>> All tests succeeded!\n")