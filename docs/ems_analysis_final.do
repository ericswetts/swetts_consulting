*THIS .DO FILE REFLECTS THE ANALYSES OF ERIC SWETTS'S MASTER'S ESSAY 
*LAST UPDATE: 4/12/2017

/*DATA NOTES:
-Dates have already been cleaned and validated with team in India.
-respondent_age4 corresponds to 4 age categories: 0-4, 5-19, 20-59,and 60+

-Contained in step 1 is the creation of contact time smoothing via random uniform number generation. 
The output has been save as <contime_uniform.dta>. The code to generate this dataset, as well as the 
code for Step 1 are saved in this dataset and are commented out below. Uncomment them to complete a fresh 
import of holiday data or the corrected dataset, or to regenerate the random numbers. 
out. 

TOC:
I) PRE-ANALYSIS CODING- CORRECT DATA VARIABLES AND CREATE DATE VARIABLES
	
1. CONTACT TIME SMOOTHING VIA RANDOM UNIFORM NUMBER GENERATION WITH 1000 ITERATIONS
PER CONTACT

(NOTE: STEPS I AND 1  are run concurrently, and the corresponding dataset is contime_uniform.dta. 
It has been commented out, so as to prevent re-creating the contact smoothing.


2.  MERGING DATE VARIABLES
	A) IMPORT HOLIDAYS
	B) MERGE DATASETS
	C) IMPORT HOLIDAY PERIOD DATA
	D) MERGE DATASETS
	C) POST-MERGE LABELING
	
(NOTE: Step 2 uses contime_uniform.dta but does not overwrite it. Thus, edits made to the holiday or 
school break excel sheets can be integrated. 

3) COLLAPSE DATA FOR KRUSKAL-WALLACE TESTING
	A) Collapse Data
	B) Re-apply titles, apply data value labels

4) HYPOTHESIS TESTING 

5) CREATION OF CHARTS
	A) BOXPLOTS
	B) HISTOGRAMS WITH MEAN/MEDIAN LINES
	
6) MISC 

=====================================================================================*/




set scheme burd

/*Set directory to "Stata file and datasets" folder*/
cd "C:\Users\Eric\Desktop\EMS- Social Mixing\Stata file and datasets"
set more off

/*

*I) PRE-ANALYSIS CODING
use "3_chart_ready.dta"

	*Data Entry Error 
	replace da4_typical=1 if pid==840136
	replace da4_typical=0 if da4_typical==2
	replace da1_date="20-Jan-16" if da1_date=="20-Jan-15"


	*Create respondent_age4 to represent 4 age categories in agreement with census:  0-4, 5-19, 20-59,and 60+
	egen respondent_age4= cut(respondent_age), at(0,5,20,60,101)
	recode respondent_age4 0=1 5=2 20=3 60=4
	label define L_respondent_age4 1 "0-4" 2 "5-19" 3 "20-59" 4 "60+"
	label values respondent_age4 L_respondent_age4


	*Create var for contact date from existing data
	gen condate= date(da1_date, "DM20Y")
	format condate %tg

	*Create Day of Week variable: Sunday=0, Sat=6
	gen dow=dow(condate)

	*Create Weekend Variables
	gen wknd=0
	replace wknd=1 if dow==0
	sort condate

	
	*Check results of respondent_age4
	table respondent_age4, contents(min respondent_age max respondent_age)

save "EMS_KW_CLEAN.dta", replace
clear


*1) CONTACT TIME SMOOTHING VIA RANDOM UNIFORM NUMBER GENERATION WITH 1000 ITERATIONS PER CONTACT

	*generate 1000 random numbers per indivividual and extract mean of them
	*formula for creating uniform integers is as follows: 
		*a=lower bound of interval, b=upper bound,
		*generate varname = floor((b–a+1)*runiform() + a)
		*timecats used: 1-4 mins, 5-14mins, 15-59mins, 1h-3h59min, 4 to 4+hours
		*Formula used to prevent undersampling of lowest and highest ends of each time interval 
		*http://blog.stata.com/2012/07/18/using-statas-random-number-generators-part-1/
	
	
use "EMS_KW_CLEAN.dta"

	set more off
	forvalues i=1/1000 {
	gen rani`i'=.
	}

	foreach x of var rani1-rani1000 {
	replace `x' = floor((4)*runiform() + 1) if d10timespent==1
	replace `x' = floor((10)*runiform() + 5) if d10timespent==2
	replace `x' = floor((45)*runiform() + 15) if d10timespent==3
	replace `x' = floor((181)*runiform() + 60) if d10timespent==4
	replace `x' = floor((240)*runiform() + 241) if d10timespent==5
	}


	*DUPLICATE OBSERVATIONS FOR GROUP EVENTS
	expand e3peopleingroup

	forvalues i=1/1000 {
	gen rang`i'=.
	}

	foreach y of var rang1-rang1000 {
	replace `y' = floor((4)*runiform() + 1) if e8averagetimespent==1
	replace `y' = floor((10)*runiform() + 5) if e8averagetimespent==2
	replace `y' = floor((45)*runiform() + 15) if e8averagetimespent==3
	replace `y' = floor((181)*runiform() + 60) if e8averagetimespent==4
	replace `y' = floor((240)*runiform() + 241) if e8averagetimespent==5
	}

	egen ranimean= rowmean(rani1-rani1000)
	egen rangmean= rowmean(rang1-rang1000)

	display c(seed)

	*To check results
	tab rani5 d10timespent
	tab rang5 e8averagetimespent
	
save contime_uniform.dta, replace
display c(seed)
clear

*/


/*
	*2) CREATION OF DATE VARIABLES

		*A) IMPORT HOLIDAY DATA
		*NOTE- MODIFY CELL RANGE IF ADDING HOLIDAYS
		import excel "Holidays.xlsx", sheet("Holidays") cellrange(A1:B41) firstrow case(lower) allstring
		gen condate= date(holdate, "DMY")
		sort condate

		*drop extraneous variables from dataset
		drop wkdy holdate

		*save Holiday dataset
	save "holiday.dta", replace
	clear



/*B) MERGE HOLIDAY Dataset- Merge holiday data with holiday dataset to identify 
contact days that are holidays as per the government*/
use "holiday.dta"

	merge 1:m condate using contime_uniform
	*Holiday Variable
	gen holiday=0
	replace holiday=1 if _merge==3

	*drop unmatched holidays from merge
	drop if _merge==1


	drop _merge

save "Holday_Dates_Merged.dta", replace
clear

	*C) IMPORT AND MERGE HOLIDAY PERIOD DATA
	import excel "Holidays.xlsx", sheet("Holiday_periods") cellrange(B1:B90) firstrow case(lower) allstring
	gen condate= date(holdate, "DMY")
	sort condate

	drop holdate

	*save Holiday dataset
save "holiday_periods.dta", replace
clear


	/*D) MERGE HOLIDAY PERIOD Dataset- Merge holiday period data to identify 
	contact days that are holiday period days*/

use "holiday_periods.dta"

	merge 1:m condate using Holday_Dates_Merged

	*Holiday Variable
	gen hol_per=0
	replace hol_per=1 if _merge==3

	*drop unmatched holiday period dates from merge
	drop if _merge==1


	*E) POST-MERGE LABELING
	*Labels for Date Variables
	label var wknd "Weekend (Sunday Only)"
	label define L_wknd 0 "Not Weekend" 1 "Weekend"
	label values wknd L_wknd

	label var dow "Day of Week"
	label define L_dow 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thursday" 5 "Friday" 6 "Saturday"
	label values dow L_dow

	label var holiday "Holiday?"
	label var hol_per "Holiday Period"

	label define L_YN 0 "No" 1 "Yes" 
	label values holiday L_YN

	label define L_atyp 0 "Atypical" 1 "Typical"
	label values da4_typical L_atyp


	*View results pre-collapse

	tab da4_typical
	tab wknd
	tab dow
	tab holiday

save "KW_pre_collapse.dta", replace
clear
*/


*3) COLLAPSE DATA FOR KRUSKAL-WALLACE TESTING
use KW_pre_collapse.dta

	*for verifying higher value of dependent vars between diffreent daytypes
	encode houseno, generate(houseno_i)

	drop rani1-rani1000
	drop rang1-rang1000

	collapse holiday da4_typical wknd dow respondent_sex condate hol_per respondent_age ///
	(max)indiv_contact_count (max)group_contact_count (max)total_contact_count respondent_age4 ///
	(sum)ranimean (sum)rangmean houseno_i, by(pid)


	*Create var for total contact time based on randomly generated numbers
	gen trc=(ranimean+rangmean)/60
	label var trc "Total Contact Time (random)"

	*Labels for Date Variables Post-collapse
	label values wknd L_wknd
	label var dow "Day of Week"
	label var da4_typical "Was Yesterday Typical?"
	label var wknd "Weekend (Sunday Only)"
	label var holiday "Holiday?"
	label var hol_per "School Break?"


	*Data Labels post-collapse
	label define L_dn 1"Normal" 2 "Daytype"
	label define L_typ 0 "Atypical" 1 "Typical"
	label define L_hol 0 "Not Holiday" 1 "Holiday"
	label define L_hol_per 0 "Non-Break" 1 "Break"
	label define L_wknd_gr 0 "Not Wknd" 1 "Weekend"
	label values holiday L_hol
	label values hol_per L_hol_per
	label values dow L_dow
	label values respondent_sex gender
	label values da4_typical L_atyp
	label values wknd L_wknd_gr



	/*View results post-collapse*/
	tab da4_typical
	tab wknd
	tab holiday
	tab hol_per



/*4) HYPOTHESIS-TESTING*/ 

*KWALLIS FOR DIFFERENCE BY DAYTYPE

	local A da4_typical wknd holiday hol_per

	foreach a of local A {

	*Differences by Day Type, Stratified by Age
	kwallis trc if respondent_sex==1, by (`a') 
	kwallis trc if respondent_sex==2, by (`a') 
	kwallis total_contact_count if respondent_sex==1, by(`a') 
	kwallis total_contact_count if respondent_sex==2, by(`a') 

	*Sumary Statistics for Sex-Stratified Analysis
	tabstat trc if respondent_sex==1, by(`a')  stat (n p50 p25 p75)
	tabstat trc if respondent_sex==2, by(`a')  stat (n p50 p25 p75)
	tabstat total_contact_count if respondent_sex==1, by(`a')  stat (n p50 p25 p75)
	tabstat total_contact_count if respondent_sex==2, by(`a')  stat (n p50 p25 p75)
}


	*Creation of Age-Stratified Daytype variables(for Holidays, Sunday, School Breaks, and ATypical Days)
	local Z da4_typical wknd holiday hol_per 
	foreach z of local Z {

	/*For KW age-stratified Categories*/
	gen i_`z'=.

	replace i_`z'=1 if respondent_age4==1 & respondent_sex==1 & `z'==0
	replace i_`z'=2 if respondent_age4==2 & respondent_sex==1 & `z'==0
	replace i_`z'=3 if respondent_age4==3 & respondent_sex==1 & `z'==0
	replace i_`z'=4 if respondent_age4==4 & respondent_sex==1 & `z'==0

	replace i_`z'=5 if respondent_age4==1 & respondent_sex==2 & `z'==0
	replace i_`z'=6 if respondent_age4==2 & respondent_sex==2 & `z'==0
	replace i_`z'=7 if respondent_age4==3 & respondent_sex==2 & `z'==0
	replace i_`z'=8 if respondent_age4==4 & respondent_sex==2 & `z'==0

	replace i_`z'=9 if respondent_age4==1 & respondent_sex==1  & `z'==1
	replace i_`z'=10 if respondent_age4==2 & respondent_sex==1 & `z'==1
	replace i_`z'=11 if respondent_age4==3 & respondent_sex==1 & `z'==1
	replace i_`z'=12 if respondent_age4==4 & respondent_sex==1 & `z'==1

	replace i_`z'=13 if respondent_age4==1 & respondent_sex==2 & `z'==1
	replace i_`z'=14 if respondent_age4==2 & respondent_sex==2 & `z'==1
	replace i_`z'=15 if respondent_age4==3 & respondent_sex==2 & `z'==1
	replace i_`z'=16 if respondent_age4==4 & respondent_sex==2 & `z'==1


	gen dn1_`z'=.
	label var dn1_`z' "M 0-4 `z'"
	gen dn2_`z'=.
	label var dn2_`z' "M 5-19 `z'"
	gen dn3_`z'=.
	label var dn3_`z' "M 20-59 `z'"
	gen dn4_`z'=.
	label var dn4_`z' "M 60+ `z'"
	gen dn5_`z'=.
	label var dn5_`z' "F 0-4 `z'"
	gen dn6_`z'=.
	label var dn6_`z' "F 5-19 `z'"
	gen dn7_`z'=.
	label var dn7_`z' "F 20-59 `z'"
	gen dn8_`z'=.
	label var dn8_`z' "F 60+ `z'"


	replace dn1_`z'=1 if i_`z'==1 
	replace dn1_`z'=2 if i_`z'==9

	replace dn2_`z'=1 if i_`z'==2
	replace dn2_`z'=2 if i_`z'==10

	replace dn3_`z'=1 if i_`z'==3
	replace dn3_`z'=2 if i_`z'==11

	replace dn4_`z'=1 if i_`z'==4
	replace dn4_`z'=2 if i_`z'==12

	replace dn5_`z'=1 if i_`z'==5
	replace dn5_`z'=2 if i_`z'==13

	replace dn6_`z'=1 if i_`z'==6 
	replace dn6_`z'=2 if i_`z'==14

	replace dn7_`z'=1 if i_`z'==7 
	replace dn7_`z'=2 if i_`z'==15

	replace dn8_`z'=1 if i_`z'==8 
	replace dn8_`z'=2 if i_`z'==16
	label values dn1_`z' dn2_`z' dn3_`z' dn4_`z' dn5_`z' dn6_`z' dn7_`z' dn8_`z' L_dn
	}



	*For Atypical-Specific Labeling
	label define L_atyp_aw 1 "Atypical" 2 "Typical"


	local X da4_typical 
	foreach z of local X {
	label values dn1_`z' dn2_`z' dn3_`z' dn4_`z' dn5_`z' dn6_`z' dn7_`z' dn8_`z' L_atyp_aw
	}





	*Post-hoc testing by age strata:

	*FOR TRC MEN WKND
	kwallis trc, by(dn1_wknd)
	tabstat trc, by(dn1_wknd) s(n median p25 p75)
	kwallis trc, by(dn2_wknd)
	tabstat trc, by(dn2_wknd) s(n median p25 p75)
	kwallis trc, by(dn3_wknd)
	tabstat trc, by(dn3_wknd) s(n median p25 p75)
	kwallis trc, by(dn4_wknd)
	tabstat trc, by(dn4_wknd) s(n median p25 p75)

	*FOR TRC WOMEN WKND
	*TRC WOMEN WKND
	kwallis trc, by(dn5_wknd)
	tabstat trc, by(dn5_wknd) s(n median p25 p75)
	kwallis trc, by(dn6_wknd)
	tabstat trc, by(dn6_wknd) s(n median p25 p75)
	kwallis trc, by(dn7_wknd)
	tabstat trc, by(dn7_wknd) s(n median p25 p75)
	kwallis trc, by(dn8_wknd)
	tabstat trc, by(dn8_wknd) s(n median p25 p75)


	*TRC MEN HOL_PER
	kwallis trc, by(dn1_hol_per)
	tabstat trc, by(dn1_hol_per) s(n median p25 p75)
	kwallis trc, by(dn2_hol_per)
	tabstat trc, by(dn2_hol_per) s(n median p25 p75)
	kwallis trc, by(dn3_hol_per)
	tabstat trc, by(dn3_hol_per) s(n median p25 p75)
	kwallis trc, by(dn4_hol_per)
	tabstat trc, by(dn4_hol_per) s(n median p25 p75)

	*TRC WOMEN HOL_PER
	kwallis trc, by(dn5_hol_per)
	tabstat trc, by(dn5_hol_per) s(n median p25 p75)
	kwallis trc, by(dn6_hol_per)
	tabstat trc, by(dn6_hol_per) s(n median p25 p75)
	kwallis trc, by(dn7_hol_per)
	tabstat trc, by(dn7_hol_per) s(n median p25 p75)
	kwallis trc, by(dn8_hol_per)
	tabstat trc, by(dn8_hol_per) s(n median p25 p75)

	*TRC WOMEN DA4_TYPICAL
	kwallis trc, by(dn5_da4_typical)
	tabstat trc, by(dn5_da4_typical) s(n median p25 p75)
	kwallis trc, by(dn6_da4_typical)
	tabstat trc, by(dn6_da4_typical) s(n median p25 p75)
	kwallis trc, by(dn7_da4_typical)
	tabstat trc, by(dn7_da4_typical) s(n median p25 p75)
	kwallis trc, by(dn8_da4_typical)
	tabstat trc, by(dn8_da4_typical) s(n median p25 p75)

	*TCC MEN DA4_TYPICAL
	kwallis total_contact_count, by(dn1_da4_typical)
	tabstat total_contact_count, by(dn1_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn2_da4_typical)
	tabstat total_contact_count, by(dn2_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn3_da4_typical)
	tabstat total_contact_count, by(dn3_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn4_da4_typical)
	tabstat total_contact_count, by(dn4_da4_typical) s(n median p25 p75)
	*Note- there is a small sample size of 20 for one group in dn4_da4_typical


	*TCC WOMEN DA4_TYPICAL
	kwallis total_contact_count, by(dn5_da4_typical)
	tabstat total_contact_count, by(dn5_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn6_da4_typical)
	tabstat total_contact_count, by(dn6_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn7_da4_typical)
	tabstat total_contact_count, by(dn7_da4_typical) s(n median p25 p75)
	kwallis total_contact_count, by(dn8_da4_typical)
	tabstat total_contact_count, by(dn8_da4_typical) s(n median p25 p75)

	*TCC WOMEN HOL_PER
	kwallis total_contact_count, by(dn5_hol_per)
	tabstat total_contact_count, by(dn5_hol_per) s(n median p25 p75)
	kwallis total_contact_count, by(dn6_hol_per)
	tabstat total_contact_count, by(dn6_hol_per) s(n median p25 p75)
	kwallis total_contact_count, by(dn7_hol_per)
	tabstat total_contact_count, by(dn7_hol_per) s(n median p25 p75)
	kwallis total_contact_count, by(dn8_hol_per) 
	tabstat total_contact_count, by(dn8_hol_per) s(n median p25 p75)

	



*5) CREATION OF CHARTS

*A) BOXPLOTS

*BOXPLOTS FOR DAY TYPES BY TRC AND TCC

	*Boxplots of Total_contact_count
	gr box total_contact_count, over(holiday, label(angle(forty_five) labsize(small))) yscale(log) ylabel (0 2 5 10 20 50 100 150 300 600 1000) ///
	title("Holidays", size(medium) position(12)) name(a, replace) yline(5 10 20 50) ytitle("# of Contacts per Respondent")

	gr box total_contact_count, over(hol_per, label(angle(forty_five) labsize(small))) yscale(log) ylabel (0 2 5 10 20 50 100 150 300 600 1000) ///
	title("School Breaks", size(medium) position(12)) name(b, replace) yline(5 10 20 50) ytitle("")

	gr box total_contact_count, over(wknd, label(angle(forty_five) labsize(small))) yscale(log) ylabel (0 2 5 10 20 50 100 150 300 600 1000) ///
	title("Weekends", size(medium) position(12)) name(c, replace) yline(5 10 20 50) ytitle("")

	gr box total_contact_count, over(da4_typical, label(angle(forty_five) labsize(small))) yscale(log) ylabel (0 2 5 10 20 50 100 150 300 600 1000) ///
	title("Atypical Days", size(medium) position(12)) name(d, replace)  yline(5 10 20 50) ytitle("")

	gr combine a b c d, cols(4) title("Total Contact Count, by Day Type", position (12) size(medium))



	*Boxplots of TRC
	gr box trc, over(holiday, label(angle(forty_five) labsize(small))) title("Holidays", size(medium) position(12)) ///
	name(e, replace) yline(10 25 100) ytitle("Total Contact Time per Respondent,""in Hours") ylabel (0 20 50 100 150 300) 

	gr box trc, over(hol_per, label(angle(forty_five) labsize(small))) ylabel (0 20 50 100 150 300) ///
	title("School Break", size(medium) position(12)) name(f, replace) yline(10 25 100) ytitle("")

	gr box trc, over(wknd, label(angle(forty_five) labsize(small))) ylabel (0 20 50 100 150 300) ///
	title("Weekendss", size(medium) position(12)) name(g, replace) yline(10 25 100) ytitle("")

	gr box trc, over(da4_typical, label(angle(forty_five) labsize(small))) ylabel (0 20 50 100 150 300) ///
	title("Atypical Days", size(medium) position(12)) name(h, replace)  yline(10 25 100) ytitle("") 

	gr combine e f g h, cols(4) title("Total Contact Time, by Day Type", position (12) size(medium))



*B) HISTOGRAMS WITH MEAN/MEDIAN LINES
	egen m_trc=mean(trc)
	egen m_tcc=mean(total_contact_count)

	twoway histogram trc, width(5) frequency xline(43.55181, lwidth(thick) lpattern(solid) extend) xtitle(Contact time per Respondent) ///
	title(Frequency of Total Contact Time, size(large) position(12)) name(y, replace) xline(35.93067 , lwidth(thick) lcolor(green))

	twoway histogram total_contact_count if total_contact_count<610, width(1) frequency xline(24.63099 , lwidth(thick) lpattern(solid) extend) xtitle(Contacts per respondent) ///
	title(Frequency of Total Contact Count, size(large) position(12)) name(z, replace) xline(17 , lwidth(thick) lcolor(green))




*6) MISCELLANEOUS
/*

/*Conduct testing with weekend as 2-day variable*/
gen wknd_2=0
replace wknd_2=1 if dow==0 | dow==6
kwallis trc if respondent_sex==1, by(wknd_2)
kwallis trc if respondent_sex==2, by(wknd_2)
kwallis total_contact_count if respondent_sex==1, by(wknd_2)
kwallis total_contact_count if respondent_sex==2, by(wknd_2)

*Create new variable combining all three day types- Sundays, Holidays, and 
*School breaks
gen dt=0
replace dt=1 if wknd==1 | hol_per==1 | holiday==1
tab da4_typical dt

