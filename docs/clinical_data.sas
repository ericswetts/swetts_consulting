/*Clinical Data Datasets*/
libname analysis "E:\Cancer\Spring 2016 Pilot\Data Analyses\ANALYSIS-Selected";

	/*IMPORT HEIGHT DATA TO COMPENSATE FOR POSSIBLE HEIGHT RECORDING ERRORS*/

/*Copy self-height data from screener*/
data screen_clindata;
	set analysis.screen_final;
	FORMAT _all_;
	keep participant_id self_height;
	if inc=1;
   	label self_height=' ';
run;
	

/*create temp dataset for clinical_final*/
data clinical_final;
	set analysis.clinical_final;
run;


proc sort data=screen_clindata;
	by participant_id;
run;

proc sort data=clinical_final;
	by participant_id;
run;

data clinical_final;
	merge clinical_final screen_clindata;
	by participant_id;
run;

/*Data Cleaning*/
%MACRO CLEAN (B=);
data &B;
	set &B;
	if First_Height__in_=888 then First_Height__in_=.;
	if Second_Height__in_=888 then Second_Height__in_=.;
	if Third_Height__in_=888 then Third_Height__in_=.;

	if First_Weight__lbs_=888 then First_Weight__lbs_=.;
	if Second_Weight__lbs_=888 then Second_Weight__lbs_=.;
	if Third_Weight__lbs_=888 then Third_Weight__lbs_=.;

	if First__Waist__in_=888 then First__Waist__in_=.;
	if Second__Waist__in_=888 then Second__Waist__in_=.;
	if Third__Waist__in_=888 then Third__Waist__in_=.;

	if First_Height__in_=999 then First_Height__in_=.;
	if Second_Height__in_=999 then Second_Height__in_=.;
	if Third_Height__in_=999 then Third_Height__in_=.;

	if First_Weight__lbs_=999 then First_Weight__lbs_=.;
	if Second_Weight__lbs_=999 then Second_Weight__lbs_=.;
	if Third_Weight__lbs_=999 then Third_Weight__lbs_=.;

	if First__Waist__in_=999 then First__Waist__in_=.;
	if Second__Waist__in_=999 then Second__Waist__in_=.;
	if Third__Waist__in_=999 then Third__Waist__in_=.;


	avght=mean(First_Height__in_, Second_Height__in_, Third_Height__in_);
	avgwt=mean(First_Weight__lbs_, Second_Weight__lbs_, Third_Weight__lbs_);
	avgwaist=mean(First_Waist__in_, Second_Waist__in_, Third__Waist__in_);
	*BMI=((avgwt*703)/(avght*avght));
run;


%MEND CLEAN;
%CLEAN(B=Clinical_Final);


/*Create new dataset to calculate mean differences in continuous vars*/
   /*Rename vars*/

data Clinical_stack_bl;
 	set Clinical_FINAL(rename=(avgwt=avgwt_bl avgwaist=avgwaist_bl avght=avght_bl));
	if visit=1;	
run;

data Clinical_stack_pi;
 	set Clinical_FINAL(rename=(avgwt=avgwt_pi avgwaist=avgwaist_pi avght=avght_pi));	
	if visit=2;
run;

proc sort data= Clinical_stack_bl;
by Participant_ID;
run;

proc sort data= Clinical_stack_pi;
by Participant_ID;
run;

/*Merge Datasets by Participant ID*/
data Clinical_Diff;
	merge Clinical_stack_bl Clinical_stack_pi;
	by Participant_ID;
	keep Participant_ID avgwt_bl avgwaist_bl   avgwt_pi avgwaist_pi avght_pi self_height;
run;

/*Calculate Average Ht and BMIs*/
data Clinical_Diff;
	set Clinical_Diff;
	avght=mean(avght_bl, avght_pi, self_height);
	BMI_bl=((avgwt_bl*703)/(avght*avght));
	BMI_pi=((avgwt_pi*703)/(avght*avght));
run;

/*Calculate Percent change*/
data Clinical_Diff;
	set Clinical_diff;
	BMI_pct=((BMI_pi-bmi_bl)/BMI_pi)*100;
	avgwt_pct=((avgwt_pi-avgwt_bl)/avgwt_pi)*100;
	avgwaist_pct=((avgwaist_pi-avgwaist_bl)/avgwaist_pi)*100;
	avght_pct=((avght_pi-avght_bl)/avght_pi)*100;
run;




/*Calculate average weight, waist, and bmi loss*/
data Clinical_Diff;
	set Clinical_diff;
	avgwt_d=(avgwt_pi-avgwt_bl);
	bmi_d=(bmi_pi-bmi_bl);
	avgwaist_d=(avgwaist_pi-avgwaist_bl);
run;

proc means data=clinical_diff n mean std median p25 p75;
	var bmi_pct avgwt_pct avgwaist_pct avgwt_d bmi_d avgwaist_d;
run;

/*STATISTICAL TESTS*/

/*Paired T-Test for Mean Difference*/
proc ttest data=clinical_diff;
 	var bmi_d avgwaist_d;
run;


/*Wilcoxon Signed Rank Test*/
proc univariate data=Clinical_diff;
      var avgwt_d avgwt_pct bmi_d avgwaist_d;
run;


*****Baseline clinical values for those with follow-up;
Proc means data=clinical_diff n mean std median p25 p75;
where avgwt_d ne .;
var bmi_bl bmi_pi bmi_d avgwt_bl avgwt_pi avgwt_d avgwt_pct avgwaist_bl avgwaist_pi avgwaist_d;
run;

