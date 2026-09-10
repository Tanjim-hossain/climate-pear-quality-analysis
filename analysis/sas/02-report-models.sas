/* Report-aligned model specifications reconstructed from final-report.pdf.
   This is additional implementation, not a recovered final SAS program.
   NOT executed in the packaging environment. Keep logs and inspect convergence.
   The untouched program and every original model remain in archive/original-code.
   Run Rscript scripts/prepare_data.R first, then run SAS from repository root.
*/
%let project_root = .;
options validvarname=v7;
ods html path="&project_root./results" file="report-models.html";
ods graphics on;
%macro import(name, file);
proc import datafile="&project_root./data/processed/&file" out=&name dbms=csv replace;
  getnames=yes; guessingrows=max;
run;
%mend;
%import(harvest,harvest-keyed.csv);
%import(long,long-keyed.csv);
%import(complete,complete-keyed.csv);
proc sort data=harvest; by tree_key; run;
proc sort data=long; by pear_key time; run;
proc sort data=complete; by pear_key time; run;

/* 1. Continuous quality: report equation (1), tree random intercept.
   Compound symmetry is induced within trees; climate is assigned to ecotrons.
   Explicit ecotron random-intercept sensitivity follows this model. */
proc mixed data=harvest method=reml;
  class climate(ref='Scenario 1') species(ref='Conference') location(ref='BE') tree_key;
  model quality_idx = species climate location / solution cl outp=quality_predictions;
  random intercept / subject=tree_key;
  lsmeans climate / diff=control('Scenario 1') adjust=bon cl;
run;
proc mixed data=harvest method=reml;
  title 'Sensitivity: ecotron and tree random intercepts';
  class climate(ref='Scenario 1') species(ref='Conference') location(ref='BE') ecotron_key tree_key;
  model quality_idx = species climate location / solution cl;
  random intercept / subject=ecotron_key;
  random intercept / subject=tree_key;
  lsmeans climate / diff=control('Scenario 1') adjust=bon cl;
run;
/* Reported interaction screening: use ML for fixed-effect comparisons.
   Compare these nested fits using the difference in -2 log likelihood with
   the fixed-effect dimension difference, not by merely ranking likelihoods. */
%macro quality_ml(rhs);
proc mixed data=harvest method=ml;
  class climate species location tree_key;
  model quality_idx = &rhs / solution;
  random intercept / subject=tree_key;
run;
%mend;
%quality_ml(species climate location);
%quality_ml(species|climate|location@2);

/* 2. Continuous and binary GEE comparisons, including Gaussian GEEs that are
   present in report Table 3 but absent from the supplied .sas source.
   Tree clusters match the report comparison; ecotron clusters are a sensitivity.
   Inspect both empirical and model-based SE; 16 ecotrons are few clusters. */
%macro gee(response, distribution, link, correlation, cluster);
proc genmod data=harvest;
  class climate(ref='Scenario 1') species(ref='Conference') location(ref='BE') &cluster;
  %if &distribution = binomial %then %do;
    model &response(event='1') = species climate location / dist=&distribution link=&link type3;
  %end;
  %else %do;
    model &response = species climate location / dist=&distribution link=&link type3;
  %end;
  repeated subject=&cluster / type=&correlation corrw covb modelse;
run;
%mend;
%gee(quality_idx,normal,identity,ind,tree_key);
%gee(quality_idx,normal,identity,exch,tree_key);
%gee(quality_b,binomial,logit,ind,tree_key);
%gee(quality_b,binomial,logit,exch,tree_key);
%gee(quality_b,binomial,logit,exch,ecotron_key);

/* 3. Binary quality: explicitly model good quality (event=1).
   METHOD=LAPLACE is explicit here; original GLIMMIX estimation defaults differ.
   Results must not be represented as an exact rerun of Table 5. */
proc glimmix data=harvest method=laplace;
  class climate(ref='Scenario 1') species(ref='Conference') location(ref='BE') tree_key;
  model quality_b(event='1') = species climate location / dist=binary link=logit solution cl;
  random intercept / subject=tree_key;
  lsmeans climate / diff=control('Scenario 1') adjust=bon oddsratio cl;
run;
proc glimmix data=harvest method=laplace;
  title 'Binary quality: climate-location interaction candidate';
  class climate(ref='Scenario 1') species(ref='Conference') location(ref='BE') tree_key;
  model quality_b(event='1') = species climate location climate*location / dist=binary link=logit solution;
  random intercept / subject=tree_key;
run;

/* 4. Longitudinal size: equation (3) and Table 7 include time*species.
   UN is the 2x2 covariance of pear intercept/slope, not an AR(1) residual model.
   Time=0 intercept extrapolates beyond the observed weeks 5-24.
   Climate/ecotron are confounded: comparisons describe these four units. */
%macro growth(data);
proc mixed data=&data method=reml;
  title "Longitudinal size: &data";
  class climate(ref='Scenario 1') species(ref='Conference') tree_key pear_key;
  model quality = species climate time climate*time species*time / solution cl outp=pred_&data;
  random intercept / subject=tree_key;
  random intercept time / subject=pear_key type=un;
  /* Reference level is moved to the end by REF=. Check Class Level Information. */
  estimate 'Scenario 2 minus 1: cm/week' climate*time 1 0 0 -1 / cl;
  estimate 'Scenario 3 minus 1: cm/week' climate*time 0 1 0 -1 / cl;
  estimate 'Scenario 4 minus 1: cm/week' climate*time 0 0 1 -1 / cl;
run;
/* These individual contrast intervals are nominal; compare the three
   p-values to 0.05/3, or request simultaneous intervals separately. */
proc genmod data=&data;
  class climate(ref='Scenario 1') species(ref='Conference') tree_key pear_key;
  model quality = species climate time climate*time species*time / dist=normal link=identity type3;
  repeated subject=pear_key / type=ar corrw covb modelse;
run;
%mend;
%growth(long);
%growth(complete);

/* 5. Diagnostic plots for continuous quality and all-available growth.
   Residual-vs-fitted and Q-Q plots must be assessed alongside variance
   boundaries, convergence, influential clusters and model assumptions. */
%macro diagnostics(data);
proc sgplot data=&data; scatter x=pred y=resid; refline 0 / axis=y; run;
proc univariate data=&data normal; var resid; qqplot resid / normal(mu=est sigma=est); run;
%mend;
%diagnostics(quality_predictions);
%diagnostics(pred_long);
ods html close;
title;
