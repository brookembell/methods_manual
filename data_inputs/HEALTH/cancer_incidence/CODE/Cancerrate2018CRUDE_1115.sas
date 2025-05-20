libname RAWDATA "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\\Cancer incidence\rawdata";
libname CANCER "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\\Cancer incidence\input";

data RATERAW;set rawdata.cancer;
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
run;
data rategrp;set rateraw;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="20-34 years" then n1=0; 	*age2034;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;

proc sort data=rategrp;by subgroup_id;run;


/*breast*/
data postbreast;set rawdata.postbreast;
rename breast=cancer_code_ICD_O_3;
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
rename Age_10yr_single_ages=Age_recode_10yr;
run;

data postbreast;set postbreast;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="25-34 years" then n1=0; 	*age2534;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;

/*prostate*/
data prostate;set rawdata.prostate;drop prostate prostate_advance;
cancer_code_ICD_O_3="prostate(advanced)";
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
run;

data prostate;set prostate;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="20-34 years" then n1=0; 	*age2034;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;

/*Esophagus*/

data Esophagus;set rawdata.Esophagus;drop adenomas;
rename esophagus=cancer_code_ICD_O_3;
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
run;

data Esophagus;set Esophagus;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="20-34 years" then n1=0; 	*age2034;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;

/*stomach*/
data stomach;set rawdata.stomach;
if stomach="C16.0-Cardia, NOS" then cancer_code_ICD_O_3="stomach_cardia";
if stomach="C16.1-6noncardia" then cancer_code_ICD_O_3="stomach_noncardia";
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
drop stomach;
run;

data stomach;set stomach;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="20-34 years" then n1=0; 	*age2034;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;

/*myeloma*/
data Myeloma;set rawdata.Myeloma;drop Multiplemyelomaplasma_cell_leuk;
cancer_code_ICD_O_3="myeloma";
rename RaceandoriginrecodeNHWNHBNHOHis=RACE;
run;

data Myeloma;set Myeloma;where sex<>"Male and female";
if sex="Female" then n2=0 ; * female;
if sex="Male" then n2=4  ; * male;
if race="Non-Hispanic White" then n3=1;
if race="Non-Hispanic Black" then n3=2;
if race="Hispanic (All Races)" then n3=3;
if race="OTHER" then n3=4;
if Age_recode_10yr="20-34 years" then n1=0; 	*age2034;
if Age_recode_10yr="35-44 years" then  n1=8; 	*age3544;
if Age_recode_10yr="45-54 years" then  n1=16;	*age4554;
if Age_recode_10yr="55-64 years" then  n1=24; 	*age5564;
if Age_recode_10yr="65-74 years" then  n1=32;	*age6574;
if Age_recode_10yr="75+ years" then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
rename n1=agecat ; 
rename n3=racecat ; 
rename n2=sexcat;
length grp $48;grp=trim(Age_recode_10yr)||" "||trim(sex) ||" "||trim(race);
run;




proc sort data=rategrp;by subgroup_id;run;
proc sort data=postbreast;by subgroup_id;run;
proc sort data=prostate;by subgroup_id;run;
proc sort data=Esophagus;by subgroup_id;run;
proc sort data=stomach;by subgroup_id;run;
proc sort data=Myeloma;by subgroup_id;run;



data rategrp;set rategrp postbreast prostate Esophagus stomach Myeloma;by subgroup_id;run;
data cancer.rategrp;set rategrp;run;



proc transpose data=rategrp out=ratewide1 prefix=CR_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Crude_Rate ;
run;
proc transpose data=rategrp out=ratewide2 prefix=SE_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Standard_Error ;
run;
proc transpose data=rategrp out=ratewide3 prefix=LC_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Lower_Confidence_Interval ;
run;
proc transpose data=rategrp out=ratewide4 prefix=UC_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Upper_Confidence_Interval ;
run;
proc transpose data=rategrp out=ratewide5 prefix=No_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Count ;
run;
proc transpose data=rategrp out=ratewide6 prefix=POP_;
by subgroup_id;
id cancer_code_ICD_O_3;
var Population ;
run;

data ratewide(drop=_NAME_ _LABEL_);
merge ratewide1 ratewide2 ratewide3 ratewide4 ratewide5 ratewide6;
by subgroup_id;
run;

data grpinfo;set rategrp;keep Age_recode_10yr RACE Sex subgroup_id grp ;run;
proc sort data=grpinfo nodupkey out=grpinfonew; by subgroup_id;run;
data cancerwide;merge grpinfo ratewide;run;

proc import datafile="C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Cancer incidence\Population_distribution2018.xlsx"
out=Population
dbms=xlsx replace; 
run;

data cancer;merge rategrp population;by subgroup_id;
rate_manual=count/population;
run;

data cancer;set cancer;
No_2018=rate_manual*_2018_pop;
run;
