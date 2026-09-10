# Data dictionary and lineage

All three raw CSVs and the three original processed exports are included without dropping rows or columns. The original exports were compared with transformations of the raw data in `scripts/verify_data.py`.

## Harvest: `raw/G12.outcome.data.csv`

1,942 rows, one harvested pear per row. No missing values. There are 96 trees nested in 16 ecotrons, eight ecotrons in each country; six trees per ecotron. Each climate has two ecotrons in each country.

| Column | Meaning |
|---|---|
| `ID` | Unique harvested-pear identifier |
| `location` | `BE` or `FR` |
| `ecotr_id` | Ecotron identifier; climate is assigned at this level |
| `tree_id` | Tree identifier |
| `pear_id` | Pear identifier; use the full `ID` or composite keys for harvest joins |
| `species` | `Conference` or `Doyenne` |
| `climate` | `Scenario 1` through `Scenario 4` |
| `quality_idx` | Quality index, 0–100 |

`processed/quality_binary.csv` adds `quality_b = 1` for `quality_idx >= 55`, otherwise 0. Thresholding reduces a continuous endpoint to a binary endpoint; it does not change the underlying quality measurement.

## Growth: `raw/G12.size.data.csv`

192 rows, one pear per row. Four ecotrons, eight trees and 20 scheduled weekly visits. The five identifier columns are `pear_id`, `tree_id`, `ecotr_id`, `species`, `climate`; the other 20 columns are `week_5` through `week_24`, containing **size in cm**.

- `processed/longitudinal_data.csv`: 3,840 scheduled pear–week rows; columns are the five identifiers, `time` (5–24) and `quality` (size in cm).
- `processed/time_data_clean.csv`: 3,460 rows from 173 pears with no missing weekly size. It removes 19 entire pear trajectories, not just the 203 missing cells.
- There are 3,637 observed and 203 missing measurements. Missingness is monotone after dropout; 94 Conference and 79 Doyenne pears are observed at week 24.
- First missing visits occur at week 8; the earliest last observed week is 7. These are different dropout timing conventions.
- These 192 pears form a different study design from the harvest dataset. Do not link size and harvest solely by a shared numeric `pear_id`.

## Soil: `raw/G12.soil.data.csv`

96 rows, one tree per row, with no missing values. Metadata columns: `tree_ID`, `location`, `ecotr_id`, `tree_id`, `species`, `climate`. The remaining 17 measurements enter PCA after centering and scaling.

Units below follow the supplied [soil feature definitions](../docs/soil-features.docx). The teaching note's agronomic reference ranges are retained in that source document; they are not used as hard cleaning thresholds.

| CSV column | Unit / scale | Feature meaning |
|---|---|---|
| Bulk Density | g/cm³ | Solid mass per soil volume |
| Infiltration | mm/hour | Water infiltration rate |
| Soil Porosity | % | Pore space relative to total volume |
| Soil Depth | cm | Depth to a hard layer |
| Water Holding Capacity | % | Water retained following saturation and drainage |
| Soil Nitrate | mg/kg | Nitrate content |
| Soil pH | pH scale | Soil acidity |
| Phosphorus | mg/kg | Phosphorus content |
| Potassium | mg/kg | Potassium content |
| Earthworms | number/m² | Earthworm abundance |
| Microbial Biomass C | μg/g | Carbon in microbial biomass |
| Microbial Biomass N | μg/g | Nitrogen in microbial biomass |
| Particulate Organic Matter | % | Particulate organic fraction |
| Mineralizable N | mg/kg | Mineralizable nitrogen |
| Soil Enzymes | index, 0–3 | Enzymatic activity |
| Soil Respiration | mg CO₂-C/kg soil/day | Soil carbon dioxide release |
| Total Organic Carbon | % | Carbon in soil organic matter |

R's default `read.csv` changes spaces in these headers to dots (for example, `Bulk.Density`). Raw CSV names retain spaces. PCA and LDA code account for the R names; the Python audit uses the CSV names.

For LDA, count harvested pears per `(location, ecotr_id, tree_id)` and join the counts to soil. The join is one-to-one with all 96 soil trees matched. The derived table is [soil-with-pear-counts.csv](../results/soil-with-pear-counts.csv). Counting harvested records does not establish total biological yield if unharvested or unrecorded pears exist.

## Rebuild

From the repository root, run `Rscript scripts/prepare_data.R`. This reproduces the binary and longitudinal exports and creates explicit keyed copies for the report-aligned SAS program. Missing sizes remain missing; there is no imputation. `raw/` is never overwritten.
