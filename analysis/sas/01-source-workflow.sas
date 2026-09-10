/* Complete supplied SAS workflow; see docs/analysis-audit.md before interpreting output.
   This version changes paths only. The report-aligned workflow is 02-report-models.sas. */
/* Run from repository root after scripts/prepare_data.R. */
%let project_root = .;
libname datasets "&project_root./results";

PROC IMPORT DATAFILE= "&project_root./data/raw/G12.outcome.data.csv"
            OUT= datasets.hierarchy
            DBMS=CSV REPLACE;
     	GETNAMES=YES;
     	GUESSINGROWS=MAX;
RUN;

/*LMM*/
proc mixed data=datasets.hierarchy;
	class climate(ref = "Scenario 1") species(ref = "Conference") location(ref = "BE") ecotr_id tree_id;
	model quality_idx = species climate location / solution cl 
		outpm=predmean outp=pred;
	random intercept / subject=tree_id(ecotr_id) type=un;
	random intercept / subject=ecotr_id type=un;
	estimate 'Scenario 2 vs Scenario 1' climate 1 0 0 -1 / cl;
	estimate 'Scenario 3 vs Scenario 1' climate 0 1 0 -1 / cl;
	estimate 'Scenario 4 vs Scenario 1' climate 0 0 1 -1 / cl;
run;


proc print data=predmean;
proc print data=pred;
run;


proc sgplot data=pred;
    vbox pred / category=climate 
                fillattrs=(color=ligr) 
                lineattrs=(thickness=2);
    yaxis label="Predicted Quality Index";
    xaxis label="Climate Scenario";
run;



PROC IMPORT DATAFILE= "&project_root./data/processed/quality_binary.csv"
            OUT= datasets.binary
            DBMS=CSV REPLACE;
     	GETNAMES=YES;
     	GUESSINGROWS=MAX;
RUN;

/*GEE*/
proc genmod data=datasets.binary;
	class climate(ref = "Scenario 1") species(ref = "Conference") location(ref = "BE") ecotr_id tree_id;
	model quality_b = species climate location / dist= binomial type3 link=logit;
	repeated subject = tree_id(ecotr_id) / type=exch covb corrw modelse;
	estimate 'Scenario 2 vs Scenario 1' climate 1 0 0 -1;
	estimate 'Scenario 3 vs Scenario 1' climate 0 1 0 -1;
	estimate 'Scenario 4 vs Scenario 1' climate 0 0 1 -1;
run;
/*IND give worse SE and wider CI*/
proc genmod data=datasets.binary;
	class climate(ref = "Scenario 1") species(ref = "Conference") location(ref = "BE") ecotr_id tree_id;
	model quality_b = species climate location / dist= binomial type3 link=logit;
	repeated subject = tree_id(ecotr_id) / type=ind covb corrw modelse;
	estimate 'Scenario 2 vs Scenario 1' climate 1 0 0 -1;
	estimate 'Scenario 3 vs Scenario 1' climate 0 1 0 -1;
	estimate 'Scenario 4 vs Scenario 1' climate 0 0 1 -1;
run;

/*GLM*/
proc glimmix data=datasets.binary;
	class climate(ref = "Scenario 1") species(ref = "Conference") location(ref = "BE") ecotr_id tree_id;
	model quality_b = species climate location / dist= binomial link=logit solution;
	random intercept / subject=tree_id(ecotr_id) type=un;
	random intercept / subject=ecotr_id type=un;
	estimate 'Scenario 2 vs Scenario 1' climate 1 0 0 -1 / cl;
	estimate 'Scenario 3 vs Scenario 1' climate 0 1 0 -1 / cl;
	estimate 'Scenario 4 vs Scenario 1' climate 0 0 1 -1 / cl;
run;

/*LMM Longitudinal*/
PROC IMPORT DATAFILE= "&project_root./data/processed/longitudinal_data.csv"
            OUT= datasets.longdata
            DBMS=CSV REPLACE;
     	GETNAMES=YES;
     	GUESSINGROWS=MAX;
RUN;

/* with dropout */
data datasets.longdata_clean;
    set datasets.longdata;
    quality_numeric = input(quality, ?? best32.);
    time_numeric = input(time, ?? best32.);
    drop quality time;
    rename quality_numeric = quality time_numeric = time;
run;

/* without dropout */
PROC IMPORT DATAFILE= "&project_root./data/processed/time_data_clean.csv"
            OUT= datasets.longitudinal
            DBMS=CSV REPLACE;
     	GETNAMES=YES;
RUN;


proc mixed data=datasets.longdata_clean; 
	title 'No Removal'; 
    class climate(ref = "Scenario 1") species(ref = "Conference") tree_id pear_id; 
    model quality = species climate time climate*time / solution; 
    random intercept / subject=tree_id; 
    random intercept time / subject=pear_id(tree_id) type=ar(1); 
    contrast 'Any climate scenario vs climate scenario 1'  
        climate*time 1  0  0 -1, 
        climate*time 0  1  0 -1, 
        climate*time 0  0  1 -1; 
    estimate 'climate scenario 2 - climate scenario 1' climate*time 
    1 0 0 -1; 
    estimate 'climate scenario 3 - climate scenario 1' climate*time 
    0 1 0 -1; 
    estimate 'climate scenario 4 - climate scenario 1' climate*time 
    0 0 1 -1; 
run;

/* remove dropout */
proc mixed data=datasets.longitudinal;
	title 'Remove Dropout';
    class climate(ref = "Scenario 1") species(ref = "Conference") tree_id pear_id;
    model quality = species climate time climate*time / solution;
    random intercept / subject=tree_id;
    random intercept time / subject=pear_id(tree_id) type=ar(1);
    contrast 'Any climate scenario vs climate scenario 1' 
        climate*time 1  0  0 -1,
        climate*time 0  1  0 -1,
        climate*time 0  0  1 -1;
    estimate 'climate scenario 2 - climate scenario 1' climate*time
    	1 0 0 -1;
    estimate 'climate scenario 3 - climate scenario 1' climate*time
    	0 1 0 -1;
    estimate 'climate scenario 4 - climate scenario 1' climate*time
    	0 0 1 -1;
run;

/* GEE Longitudinal*/
proc genmod data=datasets.longdata_clean;
	class climate(ref = "Scenario 1") species(ref = "Conference") tree_id pear_id;
	model quality = species climate time climate*time / dist=normal type3 link=identity;;
	repeated subject = pear_id(tree_id) / type=ar covb corrw modelse;
	estimate 'Scenario 2 vs Scenario 1' climate*time 1 0 0 -1;
	estimate 'Scenario 3 vs Scenario 1' climate*time 0 1 0 -1;
	estimate 'Scenario 4 vs Scenario 1' climate*time 0 0 1 -1;
run;

proc genmod data=datasets.longitudinal;
	class climate(ref = "Scenario 1") species(ref = "Conference") tree_id pear_id;
	model quality = species climate time climate*time / dist=normal type3 link=identity;;
	repeated subject = pear_id(tree_id) / type=ar covb corrw modelse;
	estimate 'Scenario 2 vs Scenario 1' climate*time 1 0 0 -1;
	estimate 'Scenario 3 vs Scenario 1' climate*time 0 1 0 -1;
	estimate 'Scenario 4 vs Scenario 1' climate*time 0 0 1 -1;
run;





