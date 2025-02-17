libname cvd "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\CVD incidence";

data cvd2012;set cvd.cvd2012;run;
data rate2012;set cvd.rate2012;run;
data cvd2018;set cvd.cvd2018;run;
data rate2018;set cvd.rate2018;run;

data cvdnew; set cvd2018;run;

data cvdold;set cvd2012(keep=race--TSTK);
	if age=1 then n1=0; 	*age2534;
	if age=2 then n1=8; 	*age3544;
	if age=3 then n1=16;	*age4554;
	if age=4 then n1=24; 	*age5564;
	if age=5 then n1=32; 	*age6574;
	if age=6 then n1=40; 	*age>74;
	if sex=1 then n2=0; * female;
	if sex=0 then n2=4; * male;
	subgroup_id=n1+n2+race ; 
rename AA=AA2012 IHD=IHD2012 ISTK=ISTK2012  HSTK=HSTK2012 OSTK=OSTK2012 DIAB=DM2012 HHD=HHD2012 RHD=RHD2012 ENDO=ENDO2012 OTH=OTH2012 CM=CM2012 AFF=AFF2012 PVD=PVD2012 TSTK=TSTK2012;
drop n1 n2 age race sex;
run;

data rate2012;set rate2012(keep=subgroup_id--PVD);
rename AA=AA2012 IHD=IHD2012 ISTK=ISTK2012 HSTK=HSTK2012 OSTK=OSTK2012 DM=DM2012 HHD=HHD2012 RHD=RHD2012 ENDO=ENDO2012 OTH=OTH2012 CM=CM2012 AFF=AFF2012 PVD=PVD2012 TSTK=TSTK2012;
drop age race gender;
run;
data rate2018;set rate2018;drop Group age age_label race race_label gender sex_label;run;
proc sort data=cvdold;by subgroup_id;run;
proc sort data=rate2018;by subgroup_id;run;
proc sort data=cvdnew;by subgroup_id;run;
proc sort data=rate2012;by subgroup_id;run;


data cvdcompare;merge cvdnew cvdold;by subgroup_id;run;
data cvdcompare1;merge rate2018 rate2012;by subgroup_id;run;
