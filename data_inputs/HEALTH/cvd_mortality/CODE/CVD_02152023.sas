options nofmterr;

libname OLD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25";
libname CVD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\input";


******Datasource from CDC wonder**********************************************;
/*AA*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\AA_2018_HIS20.txt'
out=CVD.AA2018HIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018HIS; set CVD.AA2018HIS20 ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018HIS;set AA2018HIS;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018HIS;set AA2018HIS;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\AA_2018_NONHIS20.txt'
out=CVD.AA2018NONHIS20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018NONHIS; set CVD.AA2018NONHIS20 ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data AA2018NONHIS;set AA2018NONHIS;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018NONHIS;set AA2018NONHIS;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;



proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\NEW\AA_2018_OTH20.txt'
out=CVD.AA2018OTH20
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2018OTH; set CVD.AA2018OTH20 ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data AA2018OTH;set AA2018OTH;
population_new=input(population,12.);Crude_rate_STANDARD_ERROR_new=input(Crude_rate_STANDARD_ERROR,12.);
rename population_new=population; rename Crude_rate_STANDARD_ERROR_new=Crude_rate_STANDARD_ERROR;
drop population Crude_rate_STANDARD_ERROR;
run;
data AA2018OTH;set AA2018OTH;
Crude_Rate_new=input(Crude_Rate,12.);
rename Crude_Rate_new=Crude_Rate;
drop Crude_Rate;
run;

data AA;set AA2018HIS AA2018NONHIS AA2018OTH;run;

proc sort data=AA;by gender race;run;

/*combine age>75yr*/
proc sql ; 
create table AA75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Five_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from AA 
where Five_year_age_groups="75-79 years" or Five_year_age_groups="80-84 years" or Five_year_age_groups="85-89 years" or Five_year_age_groups="90-94 years" or Five_year_age_groups="95-99 years" or Five_year_age_groups="100+ years"
group by gender, race; 
quit ;

data AA75b ; set AA75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 
data AA75c;set AA75b;
CRUDERATE=input(Crude_rate,10.);
run;

proc sql ; 
create table AA75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(CRUDERATE) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from AA75c  
group by gender, race ; 
quit ;

data AA1;set AA;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data AAMOTALITY;set AA1 AA75D;
drop Hispanic_origin ; 
cause="AA" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=AAMOTALITY ; by  subgroup_id ; run; 

/*AFF*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\AFF_2018_HIS.txt'
out=CVD.AFF2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018HIS; set CVD.AFF2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\AFF_2018_NONHIS.txt'
out=CVD.AFF2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018NONHIS; set CVD.AFF2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\AFF_2018_OTH.txt'
out=CVD.AFF2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2018OTH; set CVD.AFF2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data AFF;set AFF2018HIS AFF2018NONHIS AFF2018OTH;run;

/*combine age>75yr*/
proc sql ; 
create table AFF75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from AFF 
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data AFF75b ; set AFF75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 
data AFF75c;set AFF75b;
CRUDERATE=input(Crude_rate,10.);
run;

proc sql ; 
create table AFF75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(CRUDERATE) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from AFF75c  
group by gender, race ; 
quit ;

data AFF1;set AFF;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data AFFMOTALITY;set AFF1 AFF75D;
drop Hispanic_origin ; 
cause="AFF" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=AFFMOTALITY ; by  subgroup_id ; run; 

/*CM*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\CM_2018_HIS.txt'
out=CVD.CM2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018HIS; set CVD.CM2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\CM_2018_NONHIS.txt'
out=CVD.CM2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018NONHIS; set CVD.CM2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\CM_2018_OTH.txt'
out=CVD.CM2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2018OTH; set CVD.CM2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data CM2018OTH;set CM2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data CM;set CM2018HIS CM2018NONHIS CM2018OTH;run;

/*combine age>75yr*/
proc sql ; 
create table CM75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from CM
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data CM75b ; set CM75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table CM75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_Rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from CM75b  
group by gender, race ; 
quit ;


data CMMOTALITY;set CM CM75D;
drop Hispanic_origin ; 
cause="CM" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=CMMOTALITY ; by  subgroup_id ; run; 

/*DM*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\DM_2018_HIS.txt'
out=CVD.DM2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018HIS; set CVD.DM2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\DM_2018_NONHIS.txt'
out=CVD.DM2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018NONHIS; set CVD.DM2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\DM_2018_OTH.txt'
out=CVD.DM2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2018OTH; set CVD.DM2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data DM2018NONHIS;set DM2018NONHIS;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data DM2018OTH;set DM2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data DM;set DM2018HIS DM2018NONHIS DM2018OTH;run;

/*combine age>75yr*/
proc sql ; 
create table DM75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from DM
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data DM75b ; set DM75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table DM75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_Rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from DM75b  
group by gender, race ; 
quit ;


data DMMOTALITY;set DM DM75D;
drop Hispanic_origin ; 
cause="DM" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=DMMOTALITY ; by  subgroup_id ; run; 

/*ENDO*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ENDO_2018_HIS.txt'
out=CVD.ENDO2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018HIS; set CVD.ENDO2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ENDO_2018_NONHIS.txt'
out=CVD.ENDO2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018NONHIS; set CVD.ENDO2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ENDO_2018_OTH.txt'
out=CVD.ENDO2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2018OTH; set CVD.ENDO2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data ENDO;set ENDO2018HIS ENDO2018NONHIS ENDO2018OTH;run;

/*combine age>75yr*/
data ENDO1;set ENDO;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc sql ; 
create table ENDO75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from ENDO1
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data ENDO75b ; set ENDO75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table ENDO75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from ENDO75B  
group by gender, race ; 
quit ;

data ENDOMOTALITY;set ENDO1 ENDO75D;
drop Hispanic_origin ; 
cause="ENDO" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=ENDOMOTALITY ; by  subgroup_id ; run; 

/*HHD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HHD_2018_HIS.txt'
out=CVD.HHD2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018HIS; set CVD.HHD2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HHD_2018_NONHIS.txt'
out=CVD.HHD2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018NONHIS; set CVD.HHD2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HHD_2018_OTH.txt'
out=CVD.HHD2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2018OTH; set CVD.HHD2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data HHD2018HIS;set HHD2018HIS;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data HHD2018OTH;set HHD2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data HHD;set HHD2018HIS HHD2018NONHIS HHD2018OTH;run;

/*combine age>75yr*/
proc sql ; 
create table HHD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from HHD
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data HHD75b ; set HHD75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table HHD75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from HHD75B  
group by gender, race ; 
quit ;

data HHDMOTALITY;set HHD HHD75D;
drop Hispanic_origin ; 
cause="HHD" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=HHDMOTALITY ; by  subgroup_id ; run; 

/*HSTK*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HSTK_2018_HIS.txt'
out=CVD.HSTK2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018HIS; set CVD.HSTK2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HSTK_2018_NONHIS.txt'
out=CVD.HSTK2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018NONHIS; set CVD.HSTK2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\HSTK_2018_OTH.txt'
out=CVD.HSTK2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2018OTH; set CVD.HSTK2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data HSTK2018OTH;set HSTK2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data HSTK;set HSTK2018HIS HSTK2018NONHIS HSTK2018OTH;run;

/*combine age>75yr*/

proc sql ; 
create table HSTK75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from HSTK
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data HSTK75b ; set HSTK75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table HSTK75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from HSTK75B  
group by gender, race ; 
quit ;

data HSTKMOTALITY;set HSTK HSTK75D;
drop Hispanic_origin ; 
cause="HSTK" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=HSTKMOTALITY ; by  subgroup_id ; run; 

/*IHD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\IHD_2018_HIS.txt'
out=CVD.IHD2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018HIS; set CVD.IHD2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\IHD_2018_NONHIS.txt'
out=CVD.IHD2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018NONHIS; set CVD.IHD2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\IHD_2018_OTH.txt'
out=CVD.IHD2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2018OTH; set CVD.IHD2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data IHD2018OTH;set IHD2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data IHD;set IHD2018HIS IHD2018NONHIS IHD2018OTH;run;

/*combine age>75yr*/

proc sql ; 
create table IHD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from IHD
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data IHD75b ; set IHD75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table IHD75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from IHD75B  
group by gender, race ; 
quit ;

data IHDMOTALITY;set IHD IHD75D;
drop Hispanic_origin ; 
cause="IHD" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=IHDMOTALITY ; by  subgroup_id ; run; 

/*ISTK*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ISTK_2018_HIS.txt'
out=CVD.ISTK2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018HIS; set CVD.ISTK2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ISTK_2018_NONHIS.txt'
out=CVD.ISTK2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018NONHIS; set CVD.ISTK2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\ISTK_2018_OTH.txt'
out=CVD.ISTK2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2018OTH; set CVD.ISTK2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data ISTK;set ISTK2018HIS ISTK2018NONHIS ISTK2018OTH;run;

/*combine age>75yr*/
data ISTK1;set ISTK;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc sql ; 
create table ISTK75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from ISTK1
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data ISTK75b ; set ISTK75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table ISTK75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from ISTK75B  
group by gender, race ; 
quit ;

data ISTKMOTALITY;set ISTK1 ISTK75D;
drop Hispanic_origin ; 
cause="ISTK" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=ISTKMOTALITY ; by  subgroup_id ; run; 

/*OSTK*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OSTK_2018_HIS.txt'
out=CVD.OSTK2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018HIS; set CVD.OSTK2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OSTK_2018_NONHIS.txt'
out=CVD.OSTK2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018NONHIS; set CVD.OSTK2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OSTK_2018_OTH.txt'
out=CVD.OSTK2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2018OTH; set CVD.OSTK2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data OSTK;set OSTK2018HIS OSTK2018NONHIS OSTK2018OTH;run;

/*combine age>75yr*/
data OSTK1;set OSTK;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc sql ; 
create table OSTK75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OSTK1
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data OSTK75b ; set OSTK75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table OSTK75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from OSTK75B  
group by gender, race ; 
quit ;

data OSTKMOTALITY;set OSTK1 OSTK75D;
drop Hispanic_origin ; 
cause="OSTK" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=OSTKMOTALITY ; by  subgroup_id ; run; 

/*OTH*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\OTH_2018_HIS20o.txt'
out=CVD.OTH2018HIS20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data OTH2018HIS20; set CVD.OTH2018HIS20o ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Five_year_age_groups=age_groups;
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\OTH_2018_HIS.txt'
out=CVD.OTH2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018HIS; set CVD.OTH2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Ten_year_age_groups=age_groups;
run; 

data OTH2018HIS; set OTH2018HIS20 OTH2018HIS ;run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\OTH_2018_NONHIS20o.txt'
out=CVD.OTH2018NONHIS20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data OTH2018NONHIS20; set CVD.OTH2018NONHIS20o ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Five_year_age_groups=age_groups;
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\OTH_2018_NONHIS.txt'
out=CVD.OTH2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018NONHIS; set CVD.OTH2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Ten_year_age_groups=age_groups;
run; 

data OTH2018NONHIS; set OTH2018NONHIS20 OTH2018NONHIS ;run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\OTH_2018_OTH20o.txt'
out=CVD.OTH2018OTH20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data OTH2018OTH20o; set CVD.OTH2018OTH20o ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Five_year_age_groups=age_groups;
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\OTH_2018_OTH.txt'
out=CVD.OTH2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2018OTH; set CVD.OTH2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Ten_year_age_groups=age_groups;
run; 

data OTH2018OTH;set OTH2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;
data OTH2018OTH; set OTH2018OTH20o OTH2018OTH ;run;

data OTH;set OTH2018HIS OTH2018NONHIS OTH2018OTH;run;

/*combine age>75yr & 20-34*/
proc sql ; 
create table OTH20a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OTH
where age_groups="20-24 years" or age_groups="25-34 years" 
group by gender, race; 
quit ;

data OTH20b ; set OTH20a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table OTH20D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from OTH20B  
group by gender, race ; 
quit ;

proc sql ; 
create table OTH75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OTH
where age_groups="75-84 years" or age_groups="85+ years" 
group by gender, race; 
quit ;

data OTH75b ; set OTH75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table OTH75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from OTH75B  
group by gender, race ; 
quit ;

data OTHMOTALITY20;set OTH OTH20D;
drop Hispanic_origin ; 
cause="OTH" ; 
if age_groups="20-24 years" or age_groups="25-34 years" then delete ; 
if age_groups="" then age_groups="20-34 years" ;
run;

data OTHMOTALITY;set OTHMOTALITY20 OTH75D;
drop Hispanic_origin ; 
cause="OTH" ; 
if age_groups="75-84 years" or age_groups="85+ years" then delete ; 
if age_groups="" then age_groups="75+ years" ;
if age_groups="20-34 years" then age= 1; 
if age_groups="35-44 years" then age= 2; 
if age_groups="45-54 years" then age= 3; 
if age_groups="55-64 years" then age= 4; 
if age_groups="65-74 years" then age= 5; 
if age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(age_groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=OTHMOTALITY ; by  subgroup_id ; run; 

/*PVD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\PVD_2018_HIS20o.txt'
out=CVD.PVD2018HIS20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data PVD2018HIS20; set CVD.PVD2018HIS20o ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Five_year_age_groups=age_groups;
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\PVD_2018_HIS.txt'
out=CVD.PVD2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018HIS; set CVD.PVD2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Ten_year_age_groups=age_groups;
run; 

data PVD2018HIS; set PVD2018HIS20 PVD2018HIS ;run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\PVD_2018_NONHIS20o.txt'
out=CVD.PVD2018NONHIS20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data PVD2018NONHIS20; set CVD.PVD2018NONHIS20o ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Five_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Five_year_age_groups=age_groups;
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\PVD_2018_NONHIS.txt'
out=CVD.PVD2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018NONHIS; set CVD.PVD2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
rename Ten_year_age_groups=age_groups;
run; 

data PVD2018NONHIS; set PVD2018NONHIS20 PVD2018NONHIS ;run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\Only20\PVD_2018_OTH20o.txt'
out=CVD.PVD2018OTH20o
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;
data PVD2018OTH20o; set CVD.PVD2018OTH20o ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Five_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Five_year_age_groups=age_groups;
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25\PVD_2018_OTH.txt'
out=CVD.PVD2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2018OTH; set CVD.PVD2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
rename Ten_year_age_groups=age_groups;
run; 

data PVD2018OTH;set PVD2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;
data PVD2018OTH; set PVD2018OTH20o PVD2018OTH ;run;

data PVD;set PVD2018HIS PVD2018NONHIS PVD2018OTH;run;

/*combine age>75yr & 20-34*/
proc sql ; 
create table PVD20a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OTH
where age_groups="20-24 years" or age_groups="25-34 years" 
group by gender, race; 
quit ;

data PVD20b ; set PVD20a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table PVD20D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from PVD20B  
group by gender, race ; 
quit ;

proc sql ; 
create table PVD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from PVD
where age_groups="75-84 years" or age_groups="85+ years" 
group by gender, race; 
quit ;

data PVD75b ; set PVD75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table PVD75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from PVD75B  
group by gender, race ; 
quit ;

data PVDMOTALITY20;set PVD PVD20D;
drop Hispanic_origin ; 
cause="PVD" ; 
if age_groups="20-24 years" or age_groups="25-34 years" then delete ; 
if age_groups="" then age_groups="20-34 years" ;
run;

data PVDMOTALITY;set PVDMOTALITY20 PVD75D;
drop Hispanic_origin ; 
cause="PVD" ; 
if age_groups="75-84 years" or age_groups="85+ years" then delete ; 
if age_groups="" then age_groups="75+ years" ;
if age_groups="20-34 years" then age= 1; 
if age_groups="35-44 years" then age= 2; 
if age_groups="45-54 years" then age= 3; 
if age_groups="55-64 years" then age= 4; 
if age_groups="65-74 years" then age= 5; 
if age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(age_groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=PVDMOTALITY ; by  subgroup_id ; run; 




/*RHD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\RHD_2018_HIS.txt'
out=CVD.RHD2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018HIS; set CVD.RHD2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\RHD_2018_NONHIS.txt'
out=CVD.RHD2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018NONHIS; set CVD.RHD2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\RHD_2018_OTH.txt'
out=CVD.RHD2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2018OTH; set CVD.RHD2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data RHD;set RHD2018HIS RHD2018NONHIS RHD2018OTH;run;

/*combine age>75yr*/
data RHD1;set RHD;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc sql ; 
create table RHD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from RHD1
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data RHD75b ; set RHD75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table RHD75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from RHD75B  
group by gender, race ; 
quit ;

data RHDMOTALITY;set RHD1 RHD75D;
drop Hispanic_origin ; 
cause="RHD" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=RHDMOTALITY ; by  subgroup_id ; run; 

/*TSTK*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\TSTK_2018_HIS.txt'
out=CVD.TSTK2018HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018HIS; set CVD.TSTK2018HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\TSTK_2018_NONHIS.txt'
out=CVD.TSTK2018NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018NONHIS; set CVD.TSTK2018NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\TSTK_2018_OTH.txt'
out=CVD.TSTK2018OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2018OTH; set CVD.TSTK2018OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data TSTK2018OTH;set TSTK2018OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data TSTK;set TSTK2018HIS TSTK2018NONHIS TSTK2018OTH;run;

/*combine age>75yr*/


proc sql ; 
create table TSTK75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from TSTK
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
group by gender, race; 
quit ;

data TSTK75b ; set TSTK75a ; 
Crude_rate=Crude_rate*population/popt;
Crude_rate_STANDARD_ERROR=Crude_rate_STANDARD_ERROR*population/popt ;
run; 

proc sql ; 
create table TSTK75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(Crude_rate) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from TSTK75B  
group by gender, race ; 
quit ;

data TSTKMOTALITY;set TSTK TSTK75D;
drop Hispanic_origin ; 
cause="TSTK" ; 
if Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" then delete ; 
if Ten_year_age_groups="" then Ten_year_age_groups="75+ years" ;
if Ten_year_age_groups="25-34 years" then age= 1; 
if Ten_year_age_groups="35-44 years" then age= 2; 
if Ten_year_age_groups="45-54 years" then age= 3; 
if Ten_year_age_groups="55-64 years" then age= 4; 
if Ten_year_age_groups="65-74 years" then age= 5; 
if Ten_year_age_groups="75+ years" then age= 6; 

if Gender="Female" then Sex=1; * female;
if gender="Male" then Sex=2; * male;
rename gender=gender_; rename sex=gender;
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;
	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 
	subgroup_id=n1+n2+n3 ; 
rename Crude_rate_STANDARD_ERROR=crude_se ; 	
rename race=race_ ;
rename n3=race ; 
	length grp $48;grp=trim(Ten_Year_Age_Groups)||" "||trim(gender) ||" "||trim(race);
run;

proc sort data=TSTKMOTALITY ; by  subgroup_id ; run; 

/*TOTAL*/

data CVDDeath;
attrib cause length=$5;
set AAMOTALITY AFFMOTALITY CMMOTALITY DMMOTALITY ENDOMOTALITY HHDMOTALITY HSTKMOTALITY IHDMOTALITY ISTKMOTALITY OSTKMOTALITY TSTKMOTALITY OTHMOTALITY PVDMOTALITY RHDMOTALITY;
crude_rate_n=Deaths/Population*100000;
RUN;

proc sort data=CVDdeath;by subgroup_id;run;
proc transpose data=CVDdeath out=wide1 ;
by subgroup_id;
id cause;
var deaths;
run;


proc sort data=CVDdeath;by subgroup_id age race gender ;run;

proc transpose data=CVDdeath out=wide2(drop=_NAME_) ;
by subgroup_id age race gender  ;
id cause;
var deaths;
run;

proc transpose data=CVDdeath out=wide3(drop=_NAME_) ;
by subgroup_id age race gender  ;
id cause;
var crude_rate_n;
run;

data widecvddeath;set wide2;
attrib Age_label length=$10;
attrib Sex_label length=$6;
attrib Race_label length=$3;
attrib Group length=$48;
    if age=1 then Age_label= "25-34"; 
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

data widecvdrate;set wide3;
attrib Age_label length=$10;
attrib Sex_label length=$6;
attrib Race_label length=$3;
attrib Group length=$48;
    if age=1 then Age_label= "25-34"; 
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
as select  cause ,subgroup_id, Population from CVDdeath;quit ;
