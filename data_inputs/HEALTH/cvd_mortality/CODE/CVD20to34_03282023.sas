options nofmterr;

libname new "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034";
libname CVD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\input";


******Datasource from CDC wonder**********************************************;
/*AA*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AA_2018_HIS.txt'
out=CVD.AA2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018HIS20; set CVD.AA2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018HIS20;set AA2018HIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018HIS20;set AA2018HIS20;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AA_2018_NONHIS.txt'
out=CVD.AA2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018NONHIS20; set CVD.AA2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data AA2018NONHIS20;set AA2018NONHIS20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018NONHIS20;set AA2018NONHIS20;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;



proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AA_2018_OTH.txt'
out=CVD.AA2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018OTH20; set CVD.AA2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018OTH20;set AA2018OTH20;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018OTH20;set AA2018OTH20;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;

data AA20;set AA2018HIS20 AA2018NONHIS20 AA2018OTH20;run;
data AA20;set AA20;
death=input(deaths,10.);
drop deaths;
rename CRUDERATE=Crude_rate;
run;
proc sort data=AA20;by gender race;run;

/*combine age20-34yr*/
proc sql ; 
create table AA34a 
as select 
sum(population) as popt,
sum(death) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, death, population, Crude_rate, Crude_rate_STANDARD_ERROR
from AA20 
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data AA34b ; set AA34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table AA34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from AA34b  
group by gender, race ; 
quit ;

data AA34D;set AA34D;
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

data AAMOTALITY34;set AAMOTALITY AA34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AFF_2018_HIS.txt'
out=CVD.AFF2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018HIS20; set CVD.AFF2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AFF_2018_NONHIS.txt'
out=CVD.AFF2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018NONHIS20; set CVD.AFF2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\AFF_2018_OTH.txt'
out=CVD.AFF2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018OTH20; set CVD.AFF2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data AFF20;set AFF2018HIS20 AFF2018NONHIS20 AFF2018OTH20;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
death=input(deaths,10.);
Crude_rate_STANDARDERROR=input(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate_STANDARD_ERROR;
drop deaths;run;


/*combine age20-34yr*/
proc sql ; 
create table AFF34a 
as select 
sum(population) as popt,
sum(death) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, death, population, Crude_rate, Crude_rate_STANDARDERROR
from AFF20 
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data AFF34b ; set AFF34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARDERROR*population/popt ;
run; 
data AFF34c;set AFF34b;
CRUDERATE=input(Crude_rate,10.);
run;

proc sql ; 
create table AFF34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(CRUDERATE) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from AFF34c  
group by gender, race ; 
quit ;


data AFF34D;set AFF34D;
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

data AFFMOTALITY34;set AFFMOTALITY AFF34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\CM_2018_HIS.txt'
out=CVD.CM2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018HIS20; set CVD.CM2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\CM_2018_NONHIS.txt'
out=CVD.CM2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018NONHIS20; set CVD.CM2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\CM_2018_OTH.txt'
out=CVD.CM2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018OTH20; set CVD.CM2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data CM2018OTH20;set CM2018OTH20;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data CM20;set CM2018HIS20 CM2018NONHIS20 CM2018OTH20;run;

/*combine age20-34yr*/
proc sql ; 
create table CM34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from CM20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data CM34b ; set CM34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table CM34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_Rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from CM34b  
group by gender, race ; 
quit ;

data CM34D;set CM34D;
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

data CMMOTALITY34;set CMMOTALITY CM34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\DM_2018_HIS.txt'
out=CVD.DM2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018HIS20; set CVD.DM2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\DM_2018_NONHIS.txt'
out=CVD.DM2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018NONHIS20; set CVD.DM2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\DM_2018_OTH.txt'
out=CVD.DM2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018OTH20; set CVD.DM2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data DM2018HIS20;set DM2018HIS20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

data DM2018OTH20;set DM2018OTH20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;


data DM20;set DM2018HIS20 DM2018NONHIS20 DM2018OTH20;run;

/*combine age20-34yr*/
proc sql ; 
create table DM34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from DM20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data DM34b ; set DM34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table DM34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_Rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from DM34b  
group by gender, race ; 
quit ;

data DM34D;set DM34D;
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

data DMMOTALITY34;set DMMOTALITY DM34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ENDO_2018_HIS.txt'
out=CVD.ENDO2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018HIS20; set CVD.ENDO2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ENDO_2018_NONHIS.txt'
out=CVD.ENDO2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018NONHIS20; set CVD.ENDO2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ENDO_2018_OTH.txt'
out=CVD.ENDO2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018OTH20; set CVD.ENDO2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data ENDO20;set ENDO2018HIS20 ENDO2018NONHIS20 ENDO2018OTH20;run;

data ENDO20;set ENDO20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/
proc sql ; 
create table ENDO34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from ENDO20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data ENDO34b ; set ENDO34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table ENDO34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from ENDO34B  
group by gender, race ; 
quit ;

data ENDO34D;set ENDO34D;
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

data ENDOMOTALITY34;set ENDOMOTALITY ENDO34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HHD_2018_HIS.txt'
out=CVD.HHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018HIS20; set CVD.HHD2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HHD_2018_NONHIS.txt'
out=CVD.HHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018NONHIS20; set CVD.HHD2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HHD_2018_OTH.txt'
out=CVD.HHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018OTH20; set CVD.HHD2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


data HHD20;set HHD2018HIS20 HHD2018NONHIS20 HHD2018OTH20;run;

data HHD20;set HHD20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/
proc sql ; 
create table HHD34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from HHD20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data HHD34b ; set HHD34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table HHD34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from HHD34B  
group by gender, race ; 
quit ;

data HHD34D;set HHD34D;
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

data HHDMOTALITY34;set HHDMOTALITY HHD34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HSTK_2018_HIS.txt'
out=CVD.HSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018HIS20; set CVD.HSTK2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HSTK_2018_NONHIS.txt'
out=CVD.HSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018NONHIS20; set CVD.HSTK2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\HSTK_2018_OTH.txt'
out=CVD.HSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018OTH20; set CVD.HSTK2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data HSTK20;set HSTK2018HIS20 HSTK2018NONHIS20 HSTK2018OTH20;run;

data HSTK20;set HSTK20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;


/*combine age 20-34yr*/

proc sql ; 
create table HSTK34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from HSTK20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data HSTK34b ; set HSTK34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table HSTK34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from HSTK34B  
group by gender, race ; 
quit ;


data HSTK34D;set HSTK34D;
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

data HSTKMOTALITY34;set HSTKMOTALITY HSTK34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\IHD_2018_HIS.txt'
out=CVD.IHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018HIS20; set CVD.IHD2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\IHD_2018_NONHIS.txt'
out=CVD.IHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018NONHIS20; set CVD.IHD2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\IHD_2018_OTH.txt'
out=CVD.IHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018OTH20; set CVD.IHD2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data IHD2018OTH;set IHD2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data IHD20;set IHD2018HIS20 IHD2018NONHIS20 IHD2018OTH20;run;

data IHD20;set IHD20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/

proc sql ; 
create table IHD34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from IHD20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data IHD34b ; set IHD34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table IHD34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from IHD34B  
group by gender, race ; 
quit ;

data IHD34D;set IHD34D;
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

data IHDMOTALITY34;set IHDMOTALITY IHD34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ISTK_2018_HIS.txt'
out=CVD.ISTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018HIS20; set CVD.ISTK2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ISTK_2018_NONHIS.txt'
out=CVD.ISTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018NONHIS20; set CVD.ISTK2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\ISTK_2018_OTH.txt'
out=CVD.ISTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018OTH20; set CVD.ISTK2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


data ISTK20;set ISTK2018HIS20 ISTK2018NONHIS20 ISTK2018OTH20;run;

data ISTK20;set ISTK20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age 20-34yr*/
proc sql ; 
create table ISTK34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from ISTK20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data ISTK34b ; set ISTK34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table ISTK34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from ISTK34B  
group by gender, race ; 
quit ;

data ISTK34D;set ISTK34D;
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

data ISTKMOTALITY34;set ISTKMOTALITY ISTK34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OSTK_2018_HIS.txt'
out=CVD.OSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018HIS20; set CVD.OSTK2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OSTK_2018_NONHIS.txt'
out=CVD.OSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018NONHIS20; set CVD.OSTK2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OSTK_2018_OTH.txt'
out=CVD.OSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018OTH20; set CVD.OSTK2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data OSTK20;set OSTK2018HIS20 OSTK2018NONHIS20 OSTK2018OTH20;run;


data OSTK20;set OSTK20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/
proc sql ; 
create table OSTK34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OSTK20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data OSTK34b ; set OSTK34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table OSTK34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from OSTK34B  
group by gender, race ; 
quit ;

data OSTK34D;set OSTK34D;
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

data OSTKMOTALITY34;set OSTKMOTALITY OSTK34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OTH_2018_HIS.txt'
out=CVD.OTH2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018HIS20; set CVD.OTH2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OTH_2018_NONHIS.txt'
out=CVD.OTH2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018NONHIS20; set CVD.OTH2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\OTH_2018_OTH.txt'
out=CVD.OTH2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018OTH20; set CVD.OTH2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data OTH20;set OTH2018HIS20 OTH2018NONHIS20 OTH2018OTH20;run;


data OTH20;set OTH20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/
proc sql ; 
create table OTH34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OTH20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data OTH34b ; set OTH34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table OTH34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from OTH34B  
group by gender, race ; 
quit ;

data OTH34D;set OTH34D;
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

data OTHMOTALITY34;set OTHMOTALITY OTH34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\PVD_2018_HIS.txt'
out=CVD.PVD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018HIS20; set CVD.PVD2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\PVD_2018_NONHIS.txt'
out=CVD.PVD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018NONHIS20; set CVD.PVD2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\PVD_2018_PVD.txt'
out=CVD.PVD2018PVD20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018PVD20; set CVD.PVD2018PVD20 ;  where hispanic_origin_code <>. ;RACE="PVDER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data PVD20;set PVD2018HIS20 PVD2018NONHIS20 PVD2018PVD20;run;


data PVD20;set PVD20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/
proc sql ; 
create table PVD34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from PVD20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data PVD34b ; set PVD34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table PVD34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from PVD34B  
group by gender, race ; 
quit ;

data PVD34D;set PVD34D;
if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="PVD" then n3=4 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
run;

data PVDMOTALITY34;set PVDMOTALITY PVD34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\RHD_2018_HIS.txt'
out=CVD.RHD2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018HIS20; set CVD.RHD2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\RHD_2018_NONHIS.txt'
out=CVD.RHD2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018NONHIS20; set CVD.RHD2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\RHD_2018_OTH.txt'
out=CVD.RHD2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018OTH20; set CVD.RHD2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data RHD20;set RHD2018HIS20 RHD2018NONHIS20 RHD2018OTH20;run;

data RHD20;set RHD20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;

/*combine age20-34yr*/

proc sql ; 
create table RHD34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from RHD20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data RHD34b ; set RHD34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table RHD34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from RHD34B  
group by gender, race ; 
quit ;

data RHD34D;set RHD34D;
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

data RHDMOTALITY34;set RHDMOTALITY RHD34D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\TSTK_2018_HIS.txt'
out=CVD.TSTK2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018HIS20; set CVD.TSTK2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\TSTK_2018_NONHIS.txt'
out=CVD.TSTK2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018NONHIS20; set CVD.TSTK2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW2034\TSTK_2018_OTH.txt'
out=CVD.TSTK2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018OTH20; set CVD.TSTK2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data TSTK2018HIS20;set TSTK2018HIS20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;


data TSTK2018OTH20;set TSTK2018OTH20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;


data TSTK2018NONHIS20;set TSTK2018NONHIS20;
CRUDERATE=input(Crude_rate,10.);
Death=INPUT(Deaths,10.);
Crude_rate_STANDARDERROR=INPUT(Crude_rate_STANDARD_ERROR,10.);
drop Crude_rate Deaths Crude_rate_STANDARD_ERROR;
rename CRUDERATE=Crude_rate Death=Deaths Crude_rate_STANDARDERROR=Crude_rate_STANDARD_ERROR;
run;


data TSTK20;set TSTK2018HIS20 TSTK2018NONHIS20 TSTK2018OTH20;run;

/*combine age20-34yr*/
proc sql ; 
create table TSTK34a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from TSTK20
where Five_year_age_groups="20-24 years" or Five_year_age_groups="25-29 years" or Five_year_age_groups="30-34 years"
group by gender, race; 
quit ;

data TSTK34b ; set TSTK34a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table TSTK34D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from TSTK34B  
group by gender, race ; 
quit ;

data TSTK34D;set TSTK34D;
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

data TSTKMOTALITY34;set TSTKMOTALITY TSTK34D;
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

proc sort data=CVDdeath34;by subgroup_id;run;
proc transpose data=CVDdeath34 out=wide1 ;
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
