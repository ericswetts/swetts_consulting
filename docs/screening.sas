libname analysis 'C:\Users\swettse\Desktop\PHEAL\BL_ANALYSYS';

/*Import datasets*/

%macro IMP (A=);
PROC IMPORT OUT=analysis.&A
DATAFILE="C:\Users\swettse\Desktop\PHEAL\BL_ANALYSYS\&A"
DBMS=XLSX REPLACE;
GETNAMES=YES;
run;
%mend IMP;

/*Macro Instances*/
/*
%IMP(A=Clinical_BL_FINAL);
%IMP(A=FACIT_BL_FINAL);
%IMP(A=PAQ_BL_FINAL);
%IMP(A=Screen_FINAL);
%IMP(A=SF12_BL_FINAL);
%IMP(A=Personal_Information_FINAL);
*/

/*for Treatment dates workaround/import */
%IMP(A=Screen_BL_Dates);


/*Formats for Personal Information and Screen Datasets*/
proc format;
	value fyn 
		1="Yes"
		2="No";

	value fgender
		1="Male"
		2="Female";

	value frace
		1="American Indian or Alaska Native"
		2="-Asian"
		3="Black or African American"
		4="Native Hawaiian or Pacific Islander"
		5="White"
		6="Other";
		
	value fwork
		1="Working Full-time(>=35 hours per week)"
		2="Working Part-time(<35 hours per week)"
		3="Unemployed Seeking work"
		4="Unemployed Not Seeking Work"  
		5="Retired"
		6="Disabled";

	value fedu
		2= "Less than High School"  
		3= "High school diploma or equivalent (GED)" 
		4= "Associate Degree or vocational degree/license"
		5= "Bachelor's Degree"
		6= "Master's Degree"
		7= "Doctorate or Professional Degree";

	value fsite
		1="Breast"
		2="Colon"
		3="Other"
		999="Don't Know"
		888="N/A";
run;


/*Apply formats*/
data Analysis.Personal_information_final;
	set Analysis.Personal_information_final;
	format 
	_4__Hispanic_Latino fyn.
	_3_Sex fgender.
	_5__Race frace.
	_6__Education fedu.
	_7__Employment fwork.;
run;

data Analysis.Screen_final;
	set Analysis.Screen_final;
	format 
	_4b__Site fsite.
	_6__eligibility inc fyn.;
run;


/*Summary statistics
For Categorical Variables in Screening Form*/

/*Set 888 to missing for proc freq percentages*/
data Analysis.screen_final;
	set Analysis.screen_final;
	if _6a__Non_eligibility_reason=888 then _6a__Non_eligibility_reason=.;
run;


proc freq data=Analysis.screen_final;
 tables _1__Hear_About_Study _6__eligibility  _6a__Non_eligibility_reason _9__Eligible_but_not_interested;
run;

/*Create Dummy Variables for Enrolled Studies Participants in Screening dataset*/
data Analysis.screen_final;
	set Analysis.screen_final;
	if _6__Eligibility="1" then inc="1";
	if _6__Eligibility ne "1" then inc="2";
    if _9__Eligible_but_not_interested ne "888" then inc="2";
	label inc= "Enrolled in Study";

run;

data Analysis.screen_final;
	set Analysis.screen_final;
	format 
	inc fyn.;
run;
/*Verify successful creation of dummy variable - Only those with Inc=1 should have N=[REDACTED] 
and Number eligible should have N=[REDACTED] */

proc freq data=Analysis.screen_final;
tables inc*_6__Eligibility  _1__Hear_About_Study _1__Hear_About_Study*inc;
run;

/*Begin generating Frequency Tables*/

proc freq data=Analysis.screen_final;
tables _4b__Site _4c__stage ;
run;

proc univariate data=Analysis.Personal_information_final;
var _2__Age;
run;

proc freq data=Analysis.Personal_information_final;
tables _3_Sex _4__Hispanic_Latino _5__Race _6__Education _7__Employment;
run;

proc freq data=Analysis.screen_final;
tables _4b__Site*inc _4c__stage*inc;
run;

/*Calculating BMI from Clinical Data*/
data Clinical_bl_final;
	set analysis.Clinical_bl_final;
	if Third_Height__in_=888 then Third_Height__in_=.;
	if Third_Weight__lbs_=888 then Third_Weight__lbs_=.;
	avght=mean(First_Height__in_, Second_Height__in_, Third_Height__in_);
	avgwt=mean(First_Weight__lbs_, Second_Weight__lbs_, Third_Weight__lbs_);
	BMI=((avgwt*703)/(avght*avght));
run;


proc print data=Clinical_bl_final;
	var BMI;
run;
 
/*Print mean BMI*/

proc means data=Clinical_bl_final;
	var BMI;
run;


/*Reformatting Time since treatment completed*/
/*Drop unneeded observations*/
/*Calculate time since treatment using July 1 2016 (20636)*/

data Screen_bl_dates;
	set analysis.Screen_bl_dates;
	if SAS_TreatmentDate=. then delete;
	TreatTime=(20636-SAS_TreatmentDate);
run;

/*Mean number of days since treatment*/
proc means data=Screen_bl_dates;
	var TreatTime;
run;



/*Calculating mean age from Personal Informaton Questionnaire*/
proc means data=Analysis.Personal_information_final;
	var _2__Age;
run;

proc freq data=Analysis.Sf12_bl_final;
run;

proc print data=Analysis.screen_final;
run;



