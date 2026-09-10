# Install dependencies separately, then run from the repository root.
required <- c('rmarkdown', 'knitr', 'tidyverse', 'lattice', 'viridis', 'naniar',
              'survival', 'Hmisc', 'MASS', 'scales', 'factoextra')
missing <- required[!vapply(required, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]
if (length(missing)) stop('Install required packages: ', paste(missing, collapse = ', '))
source('scripts/prepare_data.R')
rmarkdown::render('analysis/r/01-exploratory-analysis.Rmd',
  output_dir = normalizePath('reports'), knit_root_dir = normalizePath('.'))
pdf('results/soil-analysis-r.pdf', width = 11, height = 8)
# source(..., print.eval=TRUE) prints ggplot objects as well as base-R graphics.
source('analysis/r/02-soil-analysis.R', print.eval = TRUE)
dev.off()
