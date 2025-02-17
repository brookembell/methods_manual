libname mydata "C:\Users\regin\Box\lasting_aim_3\model development\data_new\in\Population";


data demo17;set mydata.demo_j;
    if ridageyr in (20:34) then age=1;
	if ridageyr in (35:44) then age=2;
	if ridageyr in (45:54) then age=3;
	if ridageyr in (55:64) then age=4;
	if ridageyr in (65:74) then age=5;
	if ridageyr >74 then age=6 ;
	/*IF ridageyr in (51:54) then age=7;*/
	/* race group */
	if ridreth1=3 then race="NHW";/*NHW*/
	if ridreth1=4 then race="NHB";/*NHB*/
	if ridreth1 in (1,2) then race="HIS";/*HISPANIC*/
	if ridreth1 in (5) then race="OTH";/*OTHER*/

	if RIAGENDR=2 then Sex=1; * female;
    if RIAGENDR=1 then Sex=2; * male;

    if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	/*IF age=7 then n1=48;*/
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;

	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 

	subgroup_id=n1+n2+n3 ; 
run;
data demogrp;set demo17;
if subgroup_id=. then subgroup_id=0;
run;
/*old
proc freq data=demogrp;
table subgroup_id;
run;
proc freq data=demogrp;
table subgroup_id;
where ridageyr in (51:54);
run;
*/
proc surveyfreq data=demogrp;  
weight WTINT2YR;
strata sdmvstra;
cluster sdmvpsu;
table subgroup_id ;
where ridageyr>19;
run;

data demo17_new;set mydata.demo_j;
    if ridageyr in (20:34) then age=1;
	if ridageyr in (35:44) then age=2;
	if ridageyr in (45:50) then age=3;
	if ridageyr in (55:64) then age=4;
	if ridageyr in (65:74) then age=5;
	if ridageyr >74 then age=6 ;
	IF ridageyr in (51:54) then age=7;
	/* race group */
	if ridreth1=3 then race="NHW";/*NHW*/
	if ridreth1=4 then race="NHB";/*NHB*/
	if ridreth1 in (1,2) then race="HIS";/*HISPANIC*/
	if ridreth1 in (5) then race="OTH";/*OTHER*/

	if RIAGENDR=2 then Sex=1; * female;
    if RIAGENDR=1 then Sex=2; * male;

    if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	IF age=7 then n1=48;
	if sex=1 then n2=0; * female;
	if sex=2 then n2=4; * male;

	if race="NHW" then n3=1 ; 
	if race="NHB" then n3=2 ; 
	if race="HIS" then n3=3 ; 
	if race="OTH" then n3=4 ; 

	subgroup_id=n1+n2+n3 ; 
run;
data demogrp_new;set demo17_new;
if subgroup_id=. then subgroup_id=0;
run;

proc surveyfreq data=demogrp_new;  
weight WTINT2YR;
strata sdmvstra;
cluster sdmvpsu;
table subgroup_id ;
where ridageyr in(45:54);
run;
