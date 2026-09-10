# Run from the repository root: Rscript scripts/prepare_data.R
# Deterministic preprocessing with no imputation and no modification of raw files.
stopifnot(file.exists('data/raw/G12.outcome.data.csv'))
dir.create('results', showWarnings = FALSE)
dir.create('data/processed', showWarnings = FALSE, recursive = TRUE)
harvest <- read.csv('data/raw/G12.outcome.data.csv')
size <- read.csv('data/raw/G12.size.data.csv')
soil <- read.csv('data/raw/G12.soil.data.csv')
stopifnot(!anyDuplicated(harvest$ID), !anyDuplicated(size$pear_id), !anyDuplicated(soil$tree_ID))
stopifnot(all(harvest$quality_idx >= 0 & harvest$quality_idx <= 100))
harvest$quality_b <- as.integer(harvest$quality_idx >= 55)
write.csv(harvest, 'data/processed/quality_binary.csv', row.names = FALSE)
weeks <- paste0('week_', 5:24)
reshape_size <- function(x) {
  reshape(x, direction = 'long', varying = weeks,
          idvar = c('pear_id', 'tree_id', 'ecotr_id', 'species', 'climate'),
          timevar = 'time', times = 5:24, v.names = 'quality')
}
long <- reshape_size(size)
complete <- reshape_size(size[complete.cases(size[weeks]), ])
stopifnot(nrow(long) == nrow(size) * 20L)
write.csv(long, 'data/processed/longitudinal_data.csv', row.names = FALSE)
write.csv(complete, 'data/processed/time_data_clean.csv', row.names = FALSE)
# Explicit global keys avoid accidental pooling if source ID conventions change.
harvest$ecotron_key <- interaction(harvest$location, harvest$ecotr_id, drop = TRUE)
harvest$tree_key <- interaction(harvest$location, harvest$ecotr_id, harvest$tree_id, drop = TRUE)
write.csv(harvest, 'data/processed/harvest-keyed.csv', row.names = FALSE)
for (name in c('long', 'complete')) {
  x <- get(name)
  x$tree_key <- interaction(x$ecotr_id, x$tree_id, drop = TRUE)
  x$pear_key <- interaction(x$ecotr_id, x$tree_id, x$pear_id, drop = TRUE)
  write.csv(x, paste0('data/processed/', name, '-keyed.csv'), row.names = FALSE, na = '')
}
capture.output(sessionInfo(), file = 'results/session-info-r.txt')
message('Prepared binary, all-available and complete-case datasets.')
