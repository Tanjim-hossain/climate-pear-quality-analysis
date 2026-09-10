# Source audit and reproducibility status

## What was actually verified

The submitted study report was used as a historical reference during portfolio preparation. Historical rendered documents containing outdated contributor metadata are intentionally not published in the public portfolio. The repository documentation uses the supplied project evidence rather than remembered estimates from other conversations. No alternate PCA/PCR or yield-regression model has been invented or represented as part of this source set.

The independent Python audit ran successfully: 24 domain, identity, lineage and numerical checks passed. It verified all raw-to-processed values (allowing floating-point serialization differences), complete-case membership, the monotone dropout pattern and the one-to-one soil/count join. It reproduced the rounded PCA and LDA proportions from the raw datasets. Package versions and exact results are recorded in `results/validation.json`.

**Not executed here:** R Markdown rendering, R model code, SAS model fitting and any new SAS diagnostic plots. R and SAS executables were unavailable. The retained soil and SAS PDFs are source technical outputs. No green CI badge or statement of complete model reproducibility is implied.

## Findings that affect interpretation

| Finding | Source evidence | Consequence and treatment |
|---|---|---|
| Climate is assigned to ecotrons | Harvest has 16 ecotrons; each belongs to one scenario | Pears and trees are not independent climate replicates. Original tree-only inference is documented; ecotron-aware sensitivity is labelled separately. High importance, directly verified. |
| Growth has no within-climate ecotron replication | Four growth ecotrons, one per scenario | Climate and ecotron effects cannot be separated. README and guide qualify growth conclusions. High importance, directly verified. |
| Binary intercept interpretation | Reported intercept 0.3028; historical prose gave an incorrect probability interpretation | Odds ≈1.3536; conditional probability at random effect zero ≈57.51%. Portfolio prose corrects the calculation. |
| Longitudinal summary disagrees with coefficient table | Historical summary reports ≈0.0052; coefficient table reports +0.0515 | Documentation uses the explicit coefficient table and records the discrepancy. |
| Report model differs from supplied SAS | Report includes species×time and UN pear intercept/slope covariance; `.sas` omits species×time and uses AR(1) for random coefficients | The portable source keeps the supplied code. A separate unexecuted program implements the report equation. These are not labelled identical reproductions. |
| SAS PDF is incomplete | Ends during the last complete-case slope contrast | Retained PDF is documented as partial; no missing tail is presented as recovered source. The complete `.sas` remains available. |
| Harvest random effects differ by source | Report equations show one tree random intercept; SAS adds ecotron and nested tree intercepts | Keep the source distinction visible; results require fresh fitting before reconciliation. |
| Gaussian GEEs absent from supplied SAS | Reported coefficient table includes independent/exchangeable Gaussian GEE estimates | Added report-aligned implementations are explicitly new; the supplied code remains intact. |
| Binary event not explicit in source | GENMOD/GLIMMIX model statements omit `event='1'` | Modelled event must be verified from logs. Additional implementation uses event 1 explicitly. |
| Missingness assumptions overstated | Historical discussion says a full-likelihood approach avoids bias | MAR/ignorability and suitable models are required. A monotone pattern does not establish MAR. |
| Ordinary GEE and dropout | Source fits unweighted longitudinal GEE on incomplete records | Do not claim MAR robustness without the necessary assumptions or an appropriate weighted/augmented method. |
| LDA coefficient interpreted as yield evidence | Historical soil discussion treats a small pear-count coefficient as negligible climate impact | A discriminant coefficient is not a test of a climate effect on yield. Portfolio interpretation states that limitation. |
| LDA displayed on training observations | Source predicts from the same fitted data | No generalization accuracy or external validation is claimed. |
| Seven PCs described as about 80% | Raw-data eigenvalues give 79.79596% for seven and 84.19632% for eight | “About 80%” is reasonable descriptively; a strict ≥80% rule needs eight PCs. |
| Source contrast p-value needs checking | Reported Time×Scenario 4 has t≈−3.28 but p<0.0001 | That p-value is not consistent with a conventional two-sided t test for this t statistic. The guide transcribes estimates/SE only; precise inferential claims need SAS output. |
| Likelihood terminology / selection unclear | Historical discussion labels single fit values 8305.14 and 8319.69 as “LRT” | An LRT requires the difference of comparable nested-model log likelihoods and a valid reference distribution. These entries alone are insufficient to reconstruct the test. |
| Similar model-based and empirical SE used to infer correct covariance | Historical discussion compares SEs | Similarity is reassuring but does not prove covariance correctness. |
| Sample-size simulation source missing | Historical report describes 10,000 iterations; no project-specific simulation script located | Reported planning results are retained in documentation, with the source gap explicit. Teaching slides are not substituted for the missing project program. |

## Preservation and portfolio adaptations

- `archive/original-code/pmhd.sas`, the raw/processed CSVs, the retained soil PDF and retained longitudinal SAS PDF keep their supplied source content. Their checksums are recorded in `source-checksums.json`.
- `archive/original-code/eda-pmhd.Rmd` preserves the source-format analysis workflow but its author metadata has been normalized to **Tanjim Hossain** for this portfolio. It is therefore intentionally excluded from the unchanged-source checksum list.
- Historical final-report and rendered-EDA PDFs containing outdated contributor metadata are not published in this public portfolio. Their reported statistical results needed for interpretation are transcribed in the README and analysis guide.
- The EDA working copy keeps the complete analysis sequence. Added headings explain the steps. Adaptations include relative paths, HTML output, a climate key retained when pivoting the first retention table, nonmissing denominators for ecotron standard errors, ecotron line grouping and clearer missingness/size labels. The ambiguous unfaceted binary bar displays remain and are flagged in the guide.
- The SAS working copy changes paths only; candidate models and original numerical specifications are not silently replaced.
- Soil code is extracted from monospaced PDF text; the superscript caret was normalized, paths adapted, and `dplyr::select` made explicit. CSV exports of PCA variance and LDA scores are added to the working copy.
- `02-report-models.sas` is an additional implementation based on reported equations and documented sensitivities. The explicit Laplace method for its GLMM may differ from the source default GLIMMIX estimation method. Exact historical output matching is not promised.
- Python PCA and LDA are independent checks. Sign flips of score/loading axes between R and Python do not change the underlying solution. These checks do not validate mixed-model coefficients or causal claims.
- README images are generated from all relevant raw observations by the included Python script and are clearly labelled as descriptive. The editable R workflows and retained soil PDF provide the broader technical plotting sequence.

## Practical remaining work

To obtain a fully re-executed R/SAS release, render the R workflow, run both SAS programs in SAS/STAT, capture model settings and logs, resolve the report/source mismatches, and review convergence and ecotron-aware inference. Add the missing sample-size script if it is recovered. No missing output is filled with fabricated estimates.
