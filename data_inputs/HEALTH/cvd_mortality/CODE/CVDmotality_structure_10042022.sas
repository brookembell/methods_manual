libname CVD "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence";
%let home =C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence;
proc import datafile="&home\fake_CVDmortality_10042022.xlsx"
out=popsubgroup (rename=(FoodCode=food_code))
dbms=xlsx replace;
sheet="fakefromExample"; 
run;
proc import datafile="&home\USMortalityCounts2012SubsetEldersCollapsedAgeSexRace.csv"
out=CVDexample 
dbms=csv replace;
run;

proc sort data=CVDexample;by subgroup;run;
proc sort data=popsubgroup;by subgroup;run;
data fakeCVD; merge popsubgroup CVDexample;by subgroup;run;

proc transpose data=fakeCVD out=long1;by subgroup grp age age_label sex sex_label race race_label;run;
