# Source audit and reproducibility status

## What was actually verified

The original report and the older `PMHD_Report_Group_12.pdf` have the same SHA-256: they are identical files. Documentation uses this report, not remembered estimates from other conversations. No alternate PCA/PCR or yield-regression model has been invented or represented as part of this source set.

The independent Python audit ran successfully: 24 domain, identity, lineage and numerical checks passed. It verified all raw-to-processed values (allowing floating-point serialization differences), complete-case membership, the monotone dropout pattern and the one-to-one soil/count join. It reproduced the report's rounded PCA and LDA proportions from the raw datasets. Package versions and exact results are recorded in `results/validation.json`.

**Not executed here:** R Markdown rendering, R model code, SAS model fitting and any new SAS diagnostic plots. R and SAS executables were unavailable. Existing PDF outputs are preserved original outputs. No green CI badge or statement of complete model reproducibility is implied.

## Findings that affect interpretation

| Finding | Source evidence | Consequence and treatment |
|---|---|---|
| Climate is assigned to ecotrons | Harvest has 16 ecotrons; each belongs to one scenario | Pears and trees are not independent climate replicates. Original tree-only inference is documented; ecotron-aware sensitivity is labelled separately. High importance, directly verified. |
| Growth has no within-climate ecotron replication | Four growth ecotrons, one per scenario | Climate and ecotron effects cannot be separated. README and guide qualify growth conclusions. High importance, directly verified. |
| Binary intercept interpretation | Table 5 intercept 0.3028; prose says “1.3536 or 35.36” | Odds ≈1.3536; conditional probability at random effect zero ≈57.51%. Original PDF unchanged; new prose corrects the calculation. |
| Longitudinal abstract disagrees with Table 7 | Abstract reports ≈0.0052; Table 7 reports +0.0515 | Documentation uses the explicit coefficient table and records the discrepancy. |
| Report model differs from supplied SAS | Report includes species×time and UN pear intercept/slope covariance; `.sas` omits species×time and uses AR(1) for random coefficients | The portable source keeps the supplied code. A separate unexecuted program implements the report equation. These are not labelled identical reproductions. |
| SAS PDF is incomplete | Ends during the last complete-case slope contrast | Original PDF preserved. Its UN random-effect specification is documented; no missing tail is presented as recovered source. The complete `.sas` remains available. |
| Harvest random effects differ by source | Report equations show one tree random intercept; SAS adds ecotron and nested tree intercepts | Keep the source distinction visible; results require fresh fitting before reconciliation. |
| Gaussian GEEs absent from supplied SAS | Report Table 3 includes independent/exchangeable Gaussian GEE estimates | Added report-aligned implementations are explicitly new; the supplied code remains intact. |
| Binary event not explicit in source | GENMOD/GLIMMIX model statements omit `event='1'` | Modelled event must be verified from logs. Additional implementation uses event 1 explicitly. |
| Missingness assumptions overstated | Report says a full-likelihood approach avoids bias | MAR/ignorability and suitable models are required. A monotone pattern does not establish MAR. |
| Ordinary GEE and dropout | Source fits unweighted longitudinal GEE on incomplete records | Do not claim MAR robustness without the necessary assumptions or an appropriate weighted/augmented method. |
| LDA coefficient interpreted as yield evidence | Soil discussion treats a small pear-count coefficient as negligible climate impact | A discriminant coefficient is not a test of a climate effect on yield. New interpretation states that limitation. |
| LDA displayed on training observations | Source predicts from the same fitted data | No generalization accuracy or external validation claimed. |
| Seven PCs described as about 80% | Raw-data eigenvalues give 79.79596% for seven and 84.19632% for eight | “About 80%” is reasonable descriptively; a strict ≥80% rule needs eight PCs. |
| Source contrast p-value needs checking | Table 7 Time×Scenario 4 has t≈−3.28 but p<0.0001 | That p-value is not consistent with a conventional two-sided t test for this t statistic. The new guide transcribes estimates/SE only; precise inferential claims need SAS output. |
| Likelihood terminology / selection unclear | Discussion labels single fit values 8305.14 and 8319.69 as “LRT” | An LRT requires the difference of comparable nested-model log likelihoods and a valid reference distribution. These entries alone are insufficient to reconstruct the test. |
| Similar model-based and empirical SE used to infer correct covariance | Discussion compares SEs | Similarity is reassuring but does not prove covariance correctness. |
| Sample-size simulation source missing | Report describes 10,000 iterations; no project-specific simulation script located | Original results retained, with source gap explicit. Teaching slides are not substituted for the missing project program. |

## Exact preservation and adaptations

- `archive/original-code/eda-pmhd.Rmd` and `archive/original-code/pmhd.sas` preserve original bytes and author metadata.
- All supplied raw and processed CSVs preserve original bytes. `scripts/prepare_data.R` may serialize equivalent numeric values differently when rerun; raw files remain untouched.
- The four report/output PDFs preserve original bytes. The project brief and soil feature definitions remain in their supplied DOCX format.
- The EDA working copy keeps every original R code chunk. Added headings explain the steps. Changes are relative paths, HTML output, a climate key retained when pivoting the first retention table, nonmissing denominators for ecotron standard errors, ecotron line grouping and clearer missingness/size labels. The ambiguous unfaceted binary bar displays remain and are flagged in the guide.
- The SAS working copy changes paths only; candidate models and original numerical specifications are not silently replaced.
- Soil code is extracted from monospaced PDF text; the superscript caret was normalized, paths adapted, and `dplyr::select` made explicit. The extracted original text and PDF are retained. CSV exports of PCA variance and LDA scores are added to the working copy.
- `02-report-models.sas` is additional implementation based on report equations and documented sensitivities. The explicit Laplace method for its GLMM may differ from the original default GLIMMIX estimation method. Exact report matching is not promised.
- Python PCA and LDA are independent checks. Sign flips of score/loading axes between R and Python do not change the underlying solution. These checks do not validate mixed-model coefficients or causal claims.
- Original PDFs retain all plots. Additional README images are generated from all relevant raw observations by the included Python script and clearly labelled as descriptive.

## Practical remaining work

To obtain a fully re-executed R/SAS release, render the R workflow, run both SAS programs in SAS/STAT, capture the original model settings and logs, resolve the report/source mismatches, and review convergence and ecotron-aware inference. Add the missing sample-size script if it is recovered. No missing output is filled with fabricated estimates.
