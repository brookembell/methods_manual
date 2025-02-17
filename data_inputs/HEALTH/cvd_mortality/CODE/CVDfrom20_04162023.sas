options nofmterr;

libname new "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\new20";
libname CVD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\input";
%let home =C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\new20;
*run sas file CVD_041023 first*
******Datasource from CDC wonder**********************************************;
/*AA*/
proc import datafile="&home\AA_2018_HIS.txt"
out=CVD.AA2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018HIS20; set CVD.AA2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total' ;RACE="HIS" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018HIS20;set AA2018HIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;



proc import datafile="&home\AA_2018_NONHIS.txt"
out=CVD.AA2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018NONHIS20; set CVD.AA2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total' ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data AA2018NONHIS20;set AA2018NONHIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\AA_2018_OTH.txt"
out=CVD.AA2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018OTH20; set CVD.AA2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018OTH20;set AA2018OTH20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data AA20;set AA2018HIS20 AA2018NONHIS20 AA2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

proc sort data=AA20;by gender race;run;

data AAMOTALITY34;set AAMOTALITY AA20;
drop Hispanic_origin ; 
cause="AA" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;

proc sort data=AAMOTALITY34 ; by  subgroup_id ; run; 

/*AFF*/
proc import datafile="&home\AFF_2018_HIS.txt"
out=CVD.AFF2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018HIS20; set CVD.AFF2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AFF2018HIS20;set AFF2018HIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\AFF_2018_NONHIS.txt"
out=CVD.AFF2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018NONHIS20; set CVD.AFF2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AFF2018NONHIS20; set AFF2018NONHIS20 ;  
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run; 

proc import datafile="&home\AFF_2018_OTH.txt"
out=CVD.AFF2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018OTH20; set CVD.AFF2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AFF2018OTH20; set AFF2018OTH20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data AFF20;set AFF2018HIS20 AFF2018NONHIS20 AFF2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age20-34yr*/

data AFFMOTALITY34;set AFFMOTALITY AFF20;
drop Hispanic_origin ; 
cause="AFF" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=AFFMOTALITY34 ; by  subgroup_id ; run; 

/*CM*/
proc import datafile="&home\CM_2018_HIS.txt"
out=CVD.CM2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018HIS20; set CVD.CM2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data CM2018HIS20; set CM2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;run;

proc import datafile="&home\CM_2018_NONHIS.txt"
out=CVD.CM2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018NONHIS20; set CVD.CM2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data CM2018NONHIS20; set CM2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;

proc import datafile="&home\CM_2018_OTH.txt"
out=CVD.CM2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018OTH20; set CVD.CM2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP  gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data CM2018OTH20;set CM2018OTH20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data CM20;set CM2018HIS20 CM2018NONHIS20 CM2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

/*combine age20-34yr*/

data CMMOTALITY34;set CMMOTALITY CM20;
drop Hispanic_origin ; 
cause="CM" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=CMMOTALITY34 ; by  subgroup_id ; run; 




/*DM*/
proc import datafile="&home\DM_2018_HIS.txt"
out=CVD.DM2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018HIS20; set CVD.DM2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data DM2018HIS20; set DM2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\DM_2018_NONHIS.txt"
out=CVD.DM2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018NONHIS20; set CVD.DM2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total' ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data DM2018NONHIS20; set DM2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\DM_2018_OTH.txt"
out=CVD.DM2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018OTH20; set CVD.DM2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data DM2018OTH20;set DM2018OTH20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data DM20;set DM2018HIS20 DM2018NONHIS20 DM2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

/*combine age20-34yr*/

data DMMOTALITY34;set DMMOTALITY DM20;
drop Hispanic_origin ; 
cause="DM" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=DMMOTALITY34 ; by  subgroup_id ; run; 



/*ENDO*/
proc import datafile="&home\ENDO_2018_HIS.txt"
out=CVD.ENDO2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018HIS20; set CVD.ENDO2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data ENDO2018HIS20; set ENDO2018HIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\ENDO_2018_NONHIS.txt"
out=CVD.ENDO2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018NONHIS20; set CVD.ENDO2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total' ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data ENDO2018NONHIS20; set ENDO2018NONHIS20 ;  
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\ENDO_2018_OTH.txt"
out=CVD.ENDO2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018OTH20; set CVD.ENDO2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total' ;RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data ENDO2018OTH20; set ENDO2018OTH20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data ENDO20;set ENDO2018HIS20 ENDO2018NONHIS20 ENDO2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age20-34yr*/


data ENDOMOTALITY34;set ENDOMOTALITY ENDO20;
drop Hispanic_origin ; 
cause="ENDO" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=ENDOMOTALITY34 ; by  subgroup_id ; run; 


/*HHD*/
proc import datafile="&home\HHD_2018_HIS.txt"
out=CVD.HHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018HIS20; set CVD.HHD2018HIS20 ;  where hispanic_origin_code <>.  and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data HHD2018HIS20; set HHD2018HIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;
proc import datafile="&home\HHD_2018_NONHIS.txt"
out=CVD.HHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018NONHIS20; set CVD.HHD2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data HHD2018NONHIS20; set HHD2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\HHD_2018_OTH.txt"
out=CVD.HHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018OTH20; set CVD.HHD2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data HHD2018OTH20; set HHD2018OTH20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data HHD20;set HHD2018HIS20 HHD2018NONHIS20 HHD2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;



/*combine age20-34yr*/

data HHDMOTALITY34;set HHDMOTALITY HHD20;
drop Hispanic_origin ; 
cause="HHD" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=HHDMOTALITY34 ; by  subgroup_id ; run; 

/*HSTK*/
proc import datafile="&home\HSTK_2018_HIS.txt"
out=CVD.HSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018HIS20; set CVD.HSTK2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data HSTK2018HIS20; set HSTK2018HIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\HSTK_2018_NONHIS.txt"
out=CVD.HSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018NONHIS20; set CVD.HSTK2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data HSTK2018NONHIS20; set HSTK2018NONHIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\HSTK_2018_OTH.txt"
out=CVD.HSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018OTH20; set CVD.HSTK2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data HSTK2018OTH20; set HSTK2018OTH20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data HSTK20;set HSTK2018HIS20 HSTK2018NONHIS20 HSTK2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age 20-34yr*/

data HSTKMOTALITY34;set HSTKMOTALITY HSTK20;
drop Hispanic_origin ; 
cause="HSTK" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=HSTKMOTALITY34 ; by  subgroup_id ; run; 

/*IHD*/
proc import datafile="&home\IHD_2018_HIS.txt"
out=CVD.IHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018HIS20; set CVD.IHD2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data IHD2018HIS20; set IHD2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\IHD_2018_NONHIS.txt"
out=CVD.IHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018NONHIS20; set CVD.IHD2018NONHIS20 ;  where Race_Code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


data IHD2018NONHIS20; set IHD2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\IHD_2018_OTH.txt"
out=CVD.IHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018OTH20; set CVD.IHD2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data IHD2018OTH20; set IHD2018OTH20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data IHD20;set IHD2018HIS20 IHD2018NONHIS20 IHD2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 

run;



/*combine age20-34yr*/

data IHDMOTALITY34;set IHDMOTALITY IHD20;
drop Hispanic_origin ; 
cause="IHD" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=IHDMOTALITY34 ; by  subgroup_id ; run; 

/*ISTK*/
proc import datafile="&home\ISTK_2018_HIS.txt"
out=CVD.ISTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018HIS20; set CVD.ISTK2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data ISTK2018HIS20; set ISTK2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\ISTK_2018_NONHIS.txt"
out=CVD.ISTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018NONHIS20; set CVD.ISTK2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 

data ISTK2018NONHIS20; set ISTK2018NONHIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\ISTK_2018_OTH.txt"
out=CVD.ISTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018OTH20; set CVD.ISTK2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data ISTK2018OTH20; set ISTK2018OTH20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data ISTK20;set ISTK2018HIS20 ISTK2018NONHIS20 ISTK2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age 20-34yr*/
data ISTKMOTALITY34;set ISTKMOTALITY ISTK20;
drop Hispanic_origin ; 
cause="ISTK" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=ISTKMOTALITY34 ; by  subgroup_id ; run; 

/*OSTK*/
proc import datafile="&home\OSTK_2018_HIS.txt"
out=CVD.OSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018HIS20; set CVD.OSTK2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OSTK2018HIS20; set OSTK2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\OSTK_2018_NONHIS.txt"
out=CVD.OSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018NONHIS20; set CVD.OSTK2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data OSTK2018NONHIS20; set OSTK2018NONHIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;

run;


proc import datafile="&home\OSTK_2018_OTH.txt"
out=CVD.OSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018OTH20; set CVD.OSTK2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OSTK2018OTH20; set OSTK2018OTH20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);
rename population_new=population; 
rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
rename Crude_Rate_new=Crude_Rate;
rename Deaths_new=Deaths;
drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data OSTK20;set OSTK2018HIS20 OSTK2018NONHIS20 OSTK2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age20-34yr*/
data OSTKMOTALITY34;set OSTKMOTALITY OSTK20;
drop Hispanic_origin ; 
cause="OSTK" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=OSTKMOTALITY34 ; by  subgroup_id ; run; 

/*OTH*/
proc import datafile="&home\OTH_2018_HIS.txt"
out=CVD.OTH2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018HIS20; set CVD.OTH2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OTH2018HIS20; set OTH2018HIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\OTH_2018_NONHIS.txt"
out=CVD.OTH2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018NONHIS20; set CVD.OTH2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data OTH2018NONHIS20; set OTH2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\OTH_2018_OTH.txt"
out=CVD.OTH2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018OTH20; set CVD.OTH2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OTH2018OTH20; set OTH2018OTH20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data OTH20;set OTH2018HIS20 OTH2018NONHIS20 OTH2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;




/*combine age20-34yr*/

data OTHMOTALITY34;set OTHMOTALITY OTH20;
drop Hispanic_origin ; 
cause="OTH" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=OTHMOTALITY34 ; by  subgroup_id ; run; 

/*PVD*/
proc import datafile="&home\PVD_2018_HIS.txt"
out=CVD.PVD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018HIS20; set CVD.PVD2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data PVD2018HIS20; set PVD2018HIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

proc import datafile="&home\PVD_2018_NONHIS.txt"
out=CVD.PVD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018NONHIS20; set CVD.PVD2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 

data PVD2018NONHIS20; set PVD2018NONHIS20 ; 
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;

run;
proc import datafile="&home\PVD_2018_OTH.txt"
out=CVD.PVD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018PVD20; set CVD.PVD2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTH" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data PVD2018PVD20; set PVD2018PVD20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;
data PVD20;set PVD2018HIS20 PVD2018NONHIS20 PVD2018PVD20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

/*combine age20-34yr*/
data PVDMOTALITY34;set PVDMOTALITY PVD20;
drop Hispanic_origin ; 
cause="PVD" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=PVDMOTALITY34 ; by  subgroup_id ; run; 




/*RHD*/
proc import datafile="&home\RHD_2018_HIS.txt"
out=CVD.RHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018HIS20; set CVD.RHD2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data RHD2018HIS20; set RHD2018HIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;

run;

proc import datafile="&home\RHD_2018_NONHIS.txt"
out=CVD.RHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018NONHIS20; set CVD.RHD2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data RHD2018NONHIS20; set RHD2018NONHIS20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


proc import datafile="&home\RHD_2018_OTH.txt"
out=CVD.RHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018OTH20; set CVD.RHD2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data RHD2018OTH20; set RHD2018OTH20 ;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;

data RHD20;set RHD2018HIS20 RHD2018NONHIS20 RHD2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;


/*combine age20-34yr*/
data RHDMOTALITY34;set RHDMOTALITY RHD20;
drop Hispanic_origin ; 
cause="RHD" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=RHDMOTALITY34 ; by  subgroup_id ; run; 


/*TSTK*/
proc import datafile="&home\TSTK_2018_HIS.txt"
out=CVD.TSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018HIS20; set CVD.TSTK2018HIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="HIS" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile="&home\TSTK_2018_NONHIS.txt"
out=CVD.TSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018NONHIS20; set CVD.TSTK2018NONHIS20 ;  where hispanic_origin_code <>. and Notes <>'Total';
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


proc import datafile="&home\TSTK_2018_OTH.txt"
out=CVD.TSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018OTH20; set CVD.TSTK2018OTH20 ;  where hispanic_origin_code <>. and Notes <>'Total';RACE="OTHER" ;
KEEP   gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data TSTK2018HIS20;set TSTK2018HIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data TSTK2018OTH20;set TSTK2018OTH20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data TSTK2018NONHIS20;set TSTK2018NONHIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
Crude_Rate_new=input(Crude_Rate,12.);Deaths_new=input(Deaths,12.);

rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;rename Crude_Rate_new=Crude_Rate;rename Deaths_new=Deaths;

drop population Crude_rate_STANDARD_ERROR Crude_Rate Deaths;
run;


data TSTK20;set TSTK2018HIS20 TSTK2018NONHIS20 TSTK2018OTH20;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

/*combine age20-34yr*/

data TSTKMOTALITY34;set TSTKMOTALITY TSTK20;
drop Hispanic_origin ; 
cause="TSTK" ; 
if Ten_year_age_groups="25-34 years"  then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="20-34 years" ;
if Ten_year_age_groups="20-34 years" then age= 1; 
	if age=1 then n1=0; 	*age2034;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if gender=1 then n2=0; * female;
	if gender=2 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender_) ||" "||trim(race_);
run;
proc sort data=TSTKMOTALITY34 ; by  subgroup_id ; run; 



/*TOTAL*/

data CVDDeath34;
attrib cause length=$5;
set AAMOTALITY34 AFFMOTALITY34 CMMOTALITY34 DMMOTALITY34 ENDOMOTALITY34 HHDMOTALITY34 HSTKMOTALITY34 IHDMOTALITY34 ISTKMOTALITY34 OSTKMOTALITY34 TSTKMOTALITY34 OTHMOTALITY34 PVDMOTALITY34 RHDMOTALITY34;
crude_rate_n=Deaths/Population*100000;
RUN;

proc sort data=CVDDeath34;by subgroup_id;run;
proc transpose data=CVDDeath34 out=wide1 ;
by subgroup_id;
id cause;
var deaths;
run;


proc sort data=CVDdeath34;by subgroup_id age race gender ;run;

proc transpose data=CVDdeath34 out=wide2(drop=_NAME_) ;
by subgroup_id age race gender  ;
id cause;
var deaths;
run;

proc transpose data=CVDdeath34 out=wide3(drop=_NAME_) ;
by subgroup_id age race gender  ;
id cause;
var crude_rate_n;
run;

data widecvddeath34;set wide2;
attrib Age_label length=$10;
attrib Sex_label length=$6;
attrib Race_label length=$3;
attrib Group length=$48;
    if age=1 then Age_label= "20-34"; 
	if age=2 then Age_label= "35-44"; 
    if age=3 then Age_label= "45-54"; 
    if age=4 then Age_label= "55-64"; 
    if age=5 then Age_label= "65-74"; 
    if age=6 then Age_label= "75+"; 

    if race=1 then Race_label="NHW" ; 
	if race=2 then Race_label="NHB" ; 
    if race=3 then Race_label="HIS" ; 
    if race=4 then Race_label="OTH" ; 

	if gender=1 then Sex_label="Female";
	if gender=2 then Sex_label="Male";

Group=trim(Age_label)||" "||trim(Sex_label) ||" "||trim(Race_label);
run;

data widecvdrate34;set wide3;
attrib Age_label length=$10;
attrib Sex_label length=$6;
attrib Race_label length=$3;
attrib Group length=$48;
    if age=1 then Age_label= "20-34"; 
	if age=2 then Age_label= "35-44"; 
    if age=3 then Age_label= "45-54"; 
    if age=4 then Age_label= "55-64"; 
    if age=5 then Age_label= "65-74"; 
    if age=6 then Age_label= "75+"; 

    if race=1 then Race_label="NHW" ; 
	if race=2 then Race_label="NHB" ; 
    if race=3 then Race_label="HIS" ; 
    if race=4 then Race_label="OTH" ; 

	if gender=1 then Sex_label="Female";
	if gender=2 then Sex_label="Male";

Group=trim(Age_label)||" "||trim(Sex_label) ||" "||trim(Race_label);
run;

proc sql ; 
create table  population
as select  cause ,subgroup_id, Population from CVDdeath34;quit ;

/*merge suppressed*/
proc sort data=cvdorigin;by cause subgroup_id;run;
proc sort data=suppress;by cause subgroup_id;run;
data merged;merge cvdorigin suppress;by cause subgroup_id;run;
data cvdmerged;set merged;
if deaths=. then deaths=Deaths_calculated;
run;
