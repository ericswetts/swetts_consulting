

OPTIONS MLOGIC;
/*FACIT-F Scale Analysis*/
libname analysis "E:\Cancer\Spring 2016 Pilot\Data Analyses\ANALYSIS-Selected";


PROC IMPORT OUT=analysis.facit_final
DATAFILE="E:\Cancer\Spring 2016 Pilot\Data Analyses\ANALYSIS-Selected\FACIT_final.xlsx"
DBMS=XLSX REPLACE;
Sheet='FACIT';
GETNAMES=YES;
run;


/*FACIT Fatigue Scale Recode and Results*/
data facit_final;
set analysis.facit_final;
run;

%MACRO CON (B=facit_final);
/*Recode Missing Variable to "."*/
data &B;
	set analysis.&B;
if FACIT_6=999 then FACIT_6=.;
run;


/*Determine # questions answered per participant*/
data &B;
	set &B;
	n=N(FACIT_1,FACIT_2,FACIT_3,FACIT_4,FACIT_5,FACIT_6,
		FACIT_7,FACIT_8,FACIT_9,FACIT_10,FACIT_11,FACIT_12,FACIT_13);
run;

/*Calculating Item Scores(IS)
NOTE: Because missing values cannot be used in logical functions, I created the following 
workaround to account for missing value in FACIT-6*/
data &B;
	set &B;
		if n=13 then 
			IS=44-(FACIT_1+FACIT_2+FACIT_3+FACIT_4+FACIT_5+FACIT_6+
			FACIT_9+FACIT_10+FACIT_11+FACIT_12+FACIT_13)+FACIT_7+FACIT_8;

		else if n ne 13 then;	

			IS=44-(FACIT_1+FACIT_2+FACIT_3+FACIT_4+FACIT_5+
			FACIT_9+FACIT_10+FACIT_11+FACIT_12+FACIT_13)+FACIT_7+FACIT_8;
run;

/*Multiply by 13 and divide by number of answered questions as per scoring guide*/
data &B;
	set &B;
	FIS=(IS*13)/(n);
run;

/*Print Results*/
proc print data=&B noobs;
	var Participant_ID FIS;
run;

proc univariate data=&B;
	var IS;
run;

/*Sort for later merge*/
proc sort data=&B;
	by Participant_ID;
run;
%MEND CON;
%CON(B=FACIT_FINAL);



/*Merge Datasets for pct change between groups*/
data Facit_A;
	SET FACIT_FINAL;
	if visit=1;
	keep participant_id fis;
	rename FIS=FIS_bl;
run;

data Facit_B;
	SET FACIT_FINAL;
	if visit=2;
	keep participant_id fis;
	rename FIS=FIS_pi;
run;
data facit_merge;	
	merge Facit_A facit_b;
	by Participant_ID;
run;

data Facit_merge;
	set Facit_merge;
	FIS_pct=((FIS_pi-FIS_bl)/(fis_bl))*100;
	FIS_d=FIS_pi-FIS_bl;
run;
	
proc means data=Facit_merge n mean std median p25 p75;
where fis_pi ne .;
	var fis_bl fis_pi fis_d;
run;

proc ttest data=facit_merge;
var fis_d;
run;

proc univariate data=facit_merge;
var fis_d;
run;
