options nofmterr;

libname OLD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\OLD25";
libname CVD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\input";
libname micha "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012";

******Datasource from CDC wonder**********************************************;
/*AA*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AA_2012_HIS.txt'
out=CVD.AA2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2012HIS; set CVD.AA2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AA_2012_NONHIS.txt'
out=CVD.AA2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2012NONHIS; set CVD.AA2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AA_2012_OTH.txt'
out=CVD.AA2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AA2012OTH; set CVD.AA2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data AA;set AA2012HIS AA2012NONHIS AA2012OTH;run;

/*combine age>75yr*/
proc sql ; 
create table AA75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from AA 
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AFF_2012_HIS.txt'
out=CVD.AFF2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2012HIS; set CVD.AFF2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AFF_2012_NONHIS.txt'
out=CVD.AFF2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2012NONHIS; set CVD.AFF2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\AFF_2012_OTH.txt'
out=CVD.AFF2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data AFF2012OTH; set CVD.AFF2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data AFF;set AFF2012HIS AFF2012NONHIS AFF2012OTH;
CRUDERATE=input(Crude_rate,10.);
CrudeRate_StandardError=input(Crude_Rate_Standard_Error,10.);
Death=input(Deaths,10.);
drop Crude_rate Crude_Rate_Standard_Error Deaths;
rename CRUDERATE=Crude_rate;
rename CrudeRate_StandardError=Crude_Rate_Standard_Error;
rename Death=Deaths;

run;

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
run;

proc sql ; 
create table AFF75D 
as select distinct 
gender, hispanic_origin,race, 
deatht as deaths,  
popt as population, 
sum(CRUDE_RATE) as Crude_rate,
sum(Crude_rate_STANDARD_ERROR) as Crude_rate_STANDARD_ERROR 
from AFF75c  
group by gender, race ; 
quit ;


data AFFMOTALITY;set AFF AFF75D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\CM_2012_HIS.txt'
out=CVD.CM2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2012HIS; set CVD.CM2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\CM_2012_NONHIS.txt'
out=CVD.CM2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2012NONHIS; set CVD.CM2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\CM_2012_OTH.txt'
out=CVD.CM2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data CM2012OTH; set CVD.CM2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data CM2012OTH;set CM2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data CM;set CM2012HIS CM2012NONHIS CM2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\DM_2012_HIS.txt'
out=CVD.DM2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2012HIS; set CVD.DM2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\DM_2012_NONHIS.txt'
out=CVD.DM2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2012NONHIS; set CVD.DM2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\DM_2012_OTH.txt'
out=CVD.DM2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data DM2012OTH; set CVD.DM2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data DM2012NONHIS;set DM2012NONHIS;
CRUDERATE=input(Crude_rate,10.);
CrudeRate_StandardError=input(Crude_Rate_Standard_Error,10.);
Death=input(Deaths,10.);
drop Crude_rate Crude_Rate_Standard_Error Deaths;
rename CRUDERATE=Crude_rate;
rename CrudeRate_StandardError=Crude_Rate_Standard_Error;
rename Death=Deaths;
run;

data DM2012OTH;set DM2012OTH;
CRUDERATE=input(Crude_rate,10.);
CrudeRate_StandardError=input(Crude_Rate_Standard_Error,10.);
Death=input(Deaths,10.);
drop Crude_rate Crude_Rate_Standard_Error Deaths;
rename CRUDERATE=Crude_rate;
rename CrudeRate_StandardError=Crude_Rate_Standard_Error;
rename Death=Deaths;
run;


data DM;set DM2012HIS DM2012NONHIS DM2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ENDO_2012_HIS.txt'
out=CVD.ENDO2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2012HIS; set CVD.ENDO2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ENDO_2012_NONHIS.txt'
out=CVD.ENDO2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2012NONHIS; set CVD.ENDO2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ENDO_2012_OTH.txt'
out=CVD.ENDO2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ENDO2012OTH; set CVD.ENDO2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data ENDO;set ENDO2012HIS ENDO2012NONHIS ENDO2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HHD_2012_HIS.txt'
out=CVD.HHD2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2012HIS; set CVD.HHD2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HHD_2012_NONHIS.txt'
out=CVD.HHD2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2012NONHIS; set CVD.HHD2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HHD_2012_OTH.txt'
out=CVD.HHD2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HHD2012OTH; set CVD.HHD2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 


data HHD2012OTH;set HHD2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data HHD;set HHD2012HIS HHD2012NONHIS HHD2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HSTK_2012_HIS.txt'
out=CVD.HSTK2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2012HIS; set CVD.HSTK2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HSTK_2012_NONHIS.txt'
out=CVD.HSTK2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2012NONHIS; set CVD.HSTK2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\HSTK_2012_OTH.txt'
out=CVD.HSTK2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data HSTK2012OTH; set CVD.HSTK2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data HSTK2012OTH;set HSTK2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data HSTK;set HSTK2012HIS HSTK2012NONHIS HSTK2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\IHD_2012_HIS.txt'
out=CVD.IHD2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2012HIS; set CVD.IHD2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\IHD_2012_NONHIS.txt'
out=CVD.IHD2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2012NONHIS; set CVD.IHD2012NONHIS ;  where (hispanic_origin_code <>.) and (notes='') ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\IHD_2012_OTH.txt'
out=CVD.IHD2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data IHD2012OTH; set CVD.IHD2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data IHD2012OTH;set IHD2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data IHD;set IHD2012HIS IHD2012NONHIS IHD2012OTH;
where gender<>"";run;

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
data IHDMOTALITY;SET  IHDMOTALITY; where gender=1 or gender=2;run;
proc sort data=IHDMOTALITY ; by  subgroup_id ; run; 

/*ISTK*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ISTK_2012_HIS.txt'
out=CVD.ISTK2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2012HIS; set CVD.ISTK2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ISTK_2012_NONHIS.txt'
out=CVD.ISTK2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2012NONHIS; set CVD.ISTK2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\ISTK_2012_OTH.txt'
out=CVD.ISTK2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data ISTK2012OTH; set CVD.ISTK2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data ISTK;set ISTK2012HIS ISTK2012NONHIS ISTK2012OTH;run;

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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OSTK_2012_HIS.txt'
out=CVD.OSTK2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2012HIS; set CVD.OSTK2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OSTK2012HIS;set OSTK2012HIS;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OSTK_2012_NONHIS.txt'
out=CVD.OSTK2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2012NONHIS; set CVD.OSTK2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 
data OSTK2012NONHIS;set OSTK2012NONHIS;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OSTK_2012_OTH.txt'
out=CVD.OSTK2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OSTK2012OTH; set CVD.OSTK2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OSTK2012OTH;set OSTK2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;


data OSTK;set OSTK2012HIS OSTK2012NONHIS OSTK2012OTH;run;

/*combine age>75yr*/

proc sql ; 
create table OSTK75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OSTK
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

data OSTKMOTALITY;set OSTK OSTK75D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OTH_2012_HIS.txt'
out=CVD.OTH2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2012HIS; set CVD.OTH2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 
data OTH2012HIS;set OTH2012HIS;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OTH_2012_NONHIS.txt'
out=CVD.OTH2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2012NONHIS; set CVD.OTH2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\OTH_2012_OTH.txt'
out=CVD.OTH2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data OTH2012OTH; set CVD.OTH2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data OTH2012OTH;set OTH2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data OTH;set OTH2012HIS OTH2012NONHIS OTH2012OTH;run;

/*combine age>75yr*/

proc sql ; 
create table OTH75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from OTH
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
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

data OTHMOTALITY;set OTH OTH75D;
drop Hispanic_origin ; 
cause="OTH" ; 
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

proc sort data=OTHMOTALITY ; by  subgroup_id ; run; 

/*PVD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\PVD_2012_HIS.txt'
out=CVD.PVD2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2012HIS; set CVD.PVD2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\PVD_2012_NONHIS.txt'
out=CVD.PVD2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2012NONHIS; set CVD.PVD2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\PVD_2012_OTH.txt'
out=CVD.PVD2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data PVD2012OTH; set CVD.PVD2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data PVD;set PVD2012HIS PVD2012NONHIS PVD2012OTH;run;

/*combine age>75yr*/
data PVD1;set PVD;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

proc sql ; 
create table PVD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from PVD1
where Ten_year_age_groups="75-84 years" or Ten_year_age_groups="85+ years" 
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

data PVDMOTALITY;set PVD1 PVD75D;
drop Hispanic_origin ; 
cause="PVD" ; 
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

proc sort data=PVDMOTALITY ; by  subgroup_id ; run; 

/*RHD*/
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\RHD_2012_HIS.txt'
out=CVD.RHD2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2012HIS; set CVD.RHD2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\RHD_2012_NONHIS.txt'
out=CVD.RHD2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2012NONHIS; set CVD.RHD2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\RHD_2012_OTH.txt'
out=CVD.RHD2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data RHD2012OTH; set CVD.RHD2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 



data RHD;set RHD2012HIS RHD2012NONHIS RHD2012OTH;
CRUDERATE=input(Crude_rate,10.);
CrudeRate_StandardError=input(Crude_Rate_Standard_Error,10.);
Death=input(Deaths,10.);
drop Crude_rate Crude_Rate_Standard_Error Deaths;
rename CRUDERATE=Crude_rate;
rename CrudeRate_StandardError=Crude_Rate_Standard_Error;
rename Death=Deaths;
run;

/*combine age>75yr*/

proc sql ; 
create table RHD75a 
as select 
sum(population) as popt,
sum(deaths) as deatht,
Ten_year_age_groups, gender, hispanic_origin,race, deaths, population, Crude_rate, Crude_rate_STANDARD_ERROR
from RHD
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

data RHDMOTALITY;set RHD RHD75D;
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
proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\TSTK_2012_HIS.txt'
out=CVD.TSTK2012HIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2012HIS; set CVD.TSTK2012HIS ;  where hispanic_origin_code <>. ;RACE="HIS" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\TSTK_2012_NONHIS.txt'
out=CVD.TSTK2012NONHIS
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2012NONHIS; set CVD.TSTK2012NONHIS ;  where hispanic_origin_code <>. ;
if race="White" then race="NHW" ;
else race="NHB" ;
KEEP  Ten_year_age_groups gender hispanic_origin race deaths population Crude_rate Crude_rate_STANDARD_ERROR; 
run; 


proc import datafile='C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence\rawdata\2012\TSTK_2012_OTH.txt'
out=CVD.TSTK2012OTH
dbms=dlm
replace;
 delimiter = '09'x;
 guessingrows = 912;
run;

data TSTK2012OTH; set CVD.TSTK2012OTH ;  where hispanic_origin_code <>. ;RACE="OTHER" ;
KEEP  Ten_year_age_groups gender hispanic_origin RACE deaths population Crude_rate Crude_rate_STANDARD_ERROR ; 
run; 

data TSTK2012OTH;set TSTK2012OTH;
CRUDERATE=input(Crude_rate,10.);
drop Crude_rate;
rename CRUDERATE=Crude_rate;
run;

data TSTK;set TSTK2012HIS TSTK2012NONHIS TSTK2012OTH;run;

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
