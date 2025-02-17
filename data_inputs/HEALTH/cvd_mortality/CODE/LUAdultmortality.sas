
options nofmterr;

libname DATASET 'C:\Users\LWANG18\Box\NHANES_LU';   
*libname home 'C:\Users\lwang18\Box\Projects\CVD\School meal standard\Inputs\Dietary intake';   
%let home=C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\from LU\RAW;   



*************************CMD mortality ******************************8;
******Datasource from CDC wonder**********************************************;

proc import datafile = "&home\CVD_HIS.txt"
 out =CVDHIS
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;

data CVDHis; set CVDHIS ; if cause_of_death="" ; if hispanic_origin_code ne "" ;
Outcome="CVD";
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ; 
RACE="HIS" ;
run; 

proc import datafile = "&home\DB_HIS.txt"
 out =DB_HIS
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data DB_HIS; set DB_HIS ; 
if hispanic_origin_code ne "" ; 
Outcome="DB";
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
RACE="HIS" ;
run; 


proc import datafile ="&home\STROKE_HIS.txt"
 out =STROKE_HIS
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data STROKE_HIS; set STROKE_HIS ; if hispanic_origin_code ne "" ; 
Outcome="STROKE";
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
RACE="HIS" ;
run; 


proc import datafile = "&home\CVD_WB.txt"
 out =CVDWB
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data CVDWB; set CVDWB ; if cause_of_death="" ;  if race ne "" ; Outcome="CVD";
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
if race="White" then race="NHW" ;
else race="NHB" ;
run; 

proc import datafile = "&home\DB_WB.txt"
 out =DB_WB
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data DB_WB; set DB_WB ;   if race ne "" ;  Outcome="DB";
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
if race="White" then race="NHW" ;
else race="NHB" ;
run; 

proc import datafile = "&home\STROKE_WB.txt"
 out =STROKE_WB
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data STROKE_WB; set STROKE_WB;  
if race ne "" ;
Outcome="STROKE"; 
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
if race="White" then race="NHW" ;
else race="NHB" ;
run; 
proc import datafile = "&home\CVD_OTH.txt"
 out =CVDoth
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data CVDoth ; 
set CVDoth ; 
if cause_of_death="" ; 
if hispanic_origin_code ne "" ; if race = "" ; Outcome="CVD"; 
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
race="OTHER" ;
run; 

proc import datafile = "&home\DB_OTH.txt"
 out =DB_OTH
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data DB_OTH ;  set DB_OTH ; 
if hispanic_origin_code ne "" ; if race = "" ;
Outcome="DB"; 
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate  Crude_rate_STANDARD_ERROR outcome ;
race="OTHER" ;
run; 

proc import datafile = "&home\STROKE_oth.txt"
 out =STROKE_oth
 dbms = dlm
 replace;
 delimiter = '09'x;
  guessingrows = 912;
run;
data STROKE_oth ;  set STROKE_oth ; if cause_of_death="" ; 
if hispanic_origin_code ne "" ; if race = "" ;
Outcome="STROKE"; 
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR outcome ;
race="OTHER" ; 
run; 


DATA CVD ; SET CVDWB CVDHIS CVDOTH ;
run; 

proc sql ; create table CVD75a as select sum(population) as popt,sum(deaths) as deatht,Ten_year_age_groups, gender, hispanic_origin,
race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR, outcome  from CVD 
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race ; quit ;

data CVD75b ; set CVD75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; create table CVD75c as select distinct sum(Crude_rate) 
as Crude_rate,sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR,  gender, hispanic_origin,
race,  outcome, deatht as deaths,  popt as population from CVD75b  group by gender, race ; quit ;




DATA DB ; SET DB_WB DB_HIS DB_OTH ;
*RENAME  Crude_rate=DB;
*RENAME Crude_rate_STANDARD_ERROR=DB_SE ; 
RUN; 

proc sql ; create table DB75a as select sum(population) as popt,sum(deaths) as deatht, Ten_year_age_groups, gender, hispanic_origin,
race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR, outcome  from DB
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race ; quit ;

data DB75b ; set DB75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; create table DB75c as select distinct sum(Crude_rate) as Crude_rate,sum(Crude_rate_STANDARD_ERROR) 
as Crude_rate_STANDARD_ERROR,  gender, hispanic_origin, popt as population,deatht as deaths, 
race,  outcome  from DB75b  group by gender, race ; quit ;


DATA STROKE ; SET STROKE_WB STROKE_HIS STROKE_OTH ;
*RENAME  Crude_rate=STROKE; 
*RENAME Crude_rate_STANDARD_ERROR=STROKE_SE ; RUN; 

proc sql ; create table STROKE75a as select sum(population) as popt,sum(deaths) as deatht, Ten_year_age_groups, gender, hispanic_origin,
race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR, outcome  from STROKE
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race ; quit ;

data STROKE75b ; set STROKE75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; create table STROKE75c as select distinct sum(Crude_rate) as Crude_rate,sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR,  
gender, hispanic_origin, popt as population, deatht as deaths, 
race,  outcome  from STROKE75b  group by gender, race ; quit ;

data strokes ; set stroke stroke75c ; 
drop Hispanic_origin ; 
rename outcome=cause ; if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 
	if gender="Female" then n2=0; * female;
	if gender="Male" then n2=4; * male;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTHER" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
	rename Crude_rate_STANDARD_ERROR=crude_se ; 
	rename n3=race ; 
	drop race ;
	population=population/8 ; deaths=deaths/8; 
	if Gender="Female" then Sex=2; * female;
if gender="Male" then Sex=1; * male;
	if Gender="Female" then female=1; * female;
if Gender="Male" then female=0; * male;
run; 

PROC IMPORT OUT= WORK.ISTHST
            DATAFILE= "&home/IHME_stroke.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;
Data  ISTHST ; set ISTHST ; 
If age_id=10 or age_id=11 then age=1 ;
If age_id=12 or age_id=13 then age=2 ;
If age_id=14 or age_id=15 then age=3 ;
If age_id=16 or age_id=17 then age=4 ;
If age_id=232 then age=5 ;
If age_id=234 then age=6 ;
If cause_id=495 then cause="IST";
If cause_id=496 or cause_id=497 then cause="HST";
Run; 
proc sql ; create table ISTHST2 as select sum(val) as deaths, age, sex_id, cause  from ISTHST group by age, sex_id, cause ;
quit ; 

proc sort data=ISTHST2 ; BY AGE SEX_ID  ; RUN;  
 proc transpose data=ISTHST2 out=ISTHST3 prefix=death; 
id cause ; 
by age  sex_id ;
var deaths ; 
run; 
PROC SQL ; CREATE TABLE STROKES2  AS SELECT * FROM STROKES AS A FULL JOIN ISTHST3 AS B 
ON A.age = B.age AND A.sex=B.sex_id ; 
quit ; 

Data IST ; set Strokes2  ;
Crude_Rate=deathIST/(deathHST+deathIST) ;
drop deathIST deathHST sex_id ;
cause="IST" ; 
run; 
Data HST ; set Strokes2  ;
Crude_Rate=deathHST/(deathHST+deathIST) ;
drop deathIST deathHST sex_id ;
cause="HST" ;
run; 



DATA CmdMORTALITY ; SET cvd CVD75c db db75c ;
drop Hispanic_origin ; 
rename outcome=cause ; if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 
	if gender="Female" then n2=0; * female;
	if gender="Male" then n2=4; * male;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTHER" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
	rename Crude_rate_STANDARD_ERROR=crude_se ; 
	rename n3=race ; 
	drop race ;
		if Gender="Female" then Sex=2; * female;
if gender="Male" then Sex=1; * male;
	population=population/8 ; deaths=deaths/8; 
	/*get the 8 year average number of deaths */
	if Gender="Female" then female=1; * female;
if Gender="Male" then female=0; * male;
run; 

proc sort data=cmdmortality ; by Cause subgroup_id ; run; 
Data CMDmortality2 ; set CMDmortality IST HST ; run; 

proc sort data=cmdmortality2 ; by subgroup_id ; run; 

data subpop ; set CMDmortality2 ; keep subgroup_id population ; if cause="CVD" ; run; 

/*******************Update needed *****************************/

PROC IMPORT OUT= WORK.All_Cancer_Mortality
            DATAFILE= "&home\All_Cancer_Mortality_2015.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

data cancermort ;set  All_Cancer_Mortality;
if age_gp="Age_2044" then age=1 ; 
if age_gp="Age_4554" then age=3 ; 
if age_gp="Age_5564" then age=4 ; 
if age_gp="Age_over" then age=5 ; 
output ; 
 if age_gp="Age_2044" then do ; 
age=age+1 ;
output ; 
end ;
if age_gp="Age_over"  then do ; 
age=age+1 ;
output ; 
end ; 
run; 
data cancermort2 ; set cancermort ;
	if Sex="Female" then n2=0; * female;
	if Sex="Male" then n2=4; * male;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if race_gp="Non-hispanic White" then n3=1 ; 
	if race_gp="Non-hispanic Black" then n3=2 ; 
	if race_gp="Hispanic" then n3=3 ; 
	if race_gp="Other" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
	rename cancersite=cause ; 
	rename count=deaths ;
		if race_gp="Non-hispanic White" then race=1 ; 
	if race_gp="Non-hispanic Black" then race=2 ; 
	if race_gp="Hispanic" then race=3 ; 
	if race_gp="Other" then race=4;
	drop count population Sex; 
if Sex="Female" then female=1; * female;
if Sex="Male" then female=0; * male;
drop Sex ; 
run; 

proc sort data=cancermort2 ; by subgroup_id ; run; 
data cancermort3 ; merge cancermort2 subpop ; by subgroup_id ;  run; 

/****Combine CVD and cancer mortality **/
data Allmort ; set cancermort3 CMDmortality2  ;
keep age agecat sex female race cause deaths population subgroup_id CRUDE_RATE CRUDE_SE; 
IF cause="CVD" then cause="CHD" ;
agecat=age ; 
run; 

PROC EXPORT DATA= WORK.Allmort
            OUTFILE= "&home\Allmort.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;






