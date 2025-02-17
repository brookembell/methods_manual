libname RAW "C:\Users\bbell06\Box\lasting_aim_3\model development\data_new\in\SBP\RAW";
libname SBP "C:\Users\bbell06\Box\lasting_aim_3\model development\data_new\in\SBP\DATA";
*****************************************************************************************************************;
* Example SUDAAN code to replicate NCHS Data Brief No. 364, Figures 1 - 2                                      *;
* Hypertension Prevalence Among Adults Aged 18 and Over: United States, 2017Å-2018                               *;
*                                                                                                               *;
* Ostchega,Y, Fryar,CD, Nwankwo, T, Nguyen, DT. Hypertension Prevalence Among Adults Aged 18 and Over:          *; 
* United States, 2017ÅE018. NCHS Data Brief. No 364. Hyattsville, MD: National Center for Health Statistics.    *;
* 2020.                                                                                                         *; 
*                                                                                                               *;
* Available at: https://www.cdc.gov/nchs/products/databriefs/db364.htm                                          *;
*****************************************************************************************************************;

/*****HBP= systolic blood pressure of at least 140mmHg, diastolic blood pressure of at least 90mmHg, or use of antihypertensive drugs.*/
options nocenter nodate nonumber pagesize=100 linesize=150;
OPTIONS FORMCHAR="|----|+|---+=|-/\<>*";

%put Run in SAS &sysver (maintenance release and release year: &sysvlong4)
 and SUDAAN Release 11.0.1 (SAS-Callable, 32 bit version);

** Macro To Download Data from NHANES website **;

%macro CreateDS(myDS);
  %let i = 1;
  %let DS = %scan(&myDS, &i);

  %do %until(&DS = %nrstr());
    %let Suffix = %lowcase(%substr(&DS, %eval(%length(&DS)-1)));
    %if (&Suffix = _j) %then %do; filename &DS url "https://wwwn.cdc.gov/nchs/nhanes/2017-2018/&DS..xpt"; %end;
    %else %if (&Suffix = _i) %then %do; filename &DS url "https://wwwn.cdc.gov/nchs/nhanes/2015-2016/&DS..xpt"; %end;

    libname &DS xport;

    data &DS;
      set &DS..&DS;
    run;

    %let i = %eval(&i+1);
    %let DS = %scan(&myDS, &i);
  %end;
%mend CreateDS;


** HOW TO USE **;
*%CreateDS(demo bpq bpx);
%CreateDS(demo_i bpq_i bpx_i);
%CreateDS(demo_j bpq_j bpx_j);


/*data bp1516;
  merge demo_i
        bpq_i(keep=seqn bpq020 bpq050a BPQ100D)
        bpx_i(keep=seqn bpxsy1-bpxsy4 bpxdi1-bpxdi4);
                 by seqn; run; */
data bp1718;
  merge demo_j
        bpq_j(keep=seqn bpq020 bpq050a BPQ100D)
        bpx_j(keep=seqn bpxsy1-bpxsy4 bpxdi1-bpxdi4);
                 by seqn; run; 

data raw.bp1718;set bp1718;run;
data raw.bpq_j;set bpq_j;run;

data hyper_1718;
set  bp1718;
proc sort; by seqn; run;



Proc format;
 value agecatfmt    
  1="20-34" 
  2="35-44" 
  3="45-54"
  4="55-64"
  5="65-74"
  6="75+";
  value sexfmt    
  1='Men'
  2='Women'
  0,-2='All';
  value FPLfmt   
  1='<=130'
  2='130-<=350'
  3='>350';
  VALUE EDUCfmt     
  1='<HS grad or less'
  2='Some College'
  3='>=College graduate';

  value race_et4fmt 
  1='NH white'
  2='NH black'
  3='Hispanic'
  4='other';

  value hyper_newfmt   
  1="New HTN" 
  0="no hypertension";
  value hyper_oldfmt   
  1="Old HTN" 
  0="no hypertension";
  value controlfmt   
  1="Controlled" 
  0="not controlled";
 /* value sfmt      
  1='1999-2000'
  2='2001-2002'
  3='2003-2004'
  4='2005-2006'
  5='2007-2008'
  6='2009-2010'
  7='2011-2012'
  8='2013-2014'
  9='2015-2016' 
  10='2017-2018';*/
  value awarefmt    
  1="aware" 
  0="unaware";
run;


data hyper1718;
set hyper_1718;

 ** create age group category included**;
	   
        if 20 le ridageyr lt 35 then agecat=1;
   else if 35 le ridageyr lt 45 then agecat=2;
   else if 45 le ridageyr lt 55 then agecat=3;
   else if 55 le ridageyr lt 65 then agecat=4;
   else if 65 le ridageyr lt 75 then agecat=5;
   else if  ridageyr ge 75      then agecat=6;
 
*race*;

if ridreth1=3 then race_et4=1;
else if ridreth1=4 then race_et4=2;
else if ridreth1 in (1,2) then race_et4=3;
else if ridreth1=5 then race_et4=4;

*income;
if indfmpir >0.00 and indfmpir le 1.30 then FPL=1;
else if indfmpir >1.30 and indfmpir le 3.50 then FPL=2;
else if indfmpir >3.50 then FPL=3;
 
*education;

If ridageyr in (18,19) then do;
if (dmdeduc3 >=0 and dmdeduc3 <15) or dmdeduc3=55 or dmdeduc3=66 then EDUC = 1; /*HS DIPLOMA or LESS*/
else if dmdeduc3=15 then EDUC=2; 			/*Some college*/
end; 

       if dmdeduc2 in(1,2,3) then EDUC = 1; 		/*HS DIPLOMA or LESS*/
  else if dmdeduc2=4 then EDUC=2; 			/*Some college*/
  else if dmdeduc2=5  then EDUC =3; 		/*COLLEGE*/


**Hypertension prevalence;
** Count Number of Nonmissing SBP's & DBP's **;
  n_sbp = n(of bpxsy1-bpxsy4);
  n_dbp = n(of bpxdi1-bpxdi4);
  ** Set DBP Values Of 0 To Missing For Calculating Average **;
  array _DBP bpxdi1-bpxdi4;
  do over _DBP;
    if (_DBP = 0) then _DBP = .;
  end;  
  ** Calculate Mean Systolic and Diastolic **;
  mean_sbp = mean(of bpxsy1-bpxsy4);
  mean_dbp = mean(of bpxdi1-bpxdi4);
  ** Create Hypertensive Category Variable **;
    
** Create Hypertensive Category Variable (code used in previous DB definitions)************************;
  if (mean_sbp >= 130 or mean_dbp >= 80 or bpq050a = 1) then do;
    Hyper_new = 1;
if (mean_sbp >= 130 or mean_dbp >= 80) then Controlled = 0;
      else if (n_sbp > 0 and n_dbp > 0) then Controlled = 1;
end;
  else if (n_sbp > 0 and n_dbp > 0) then
    Hyper_new = 0;

	if Hyper_new = 1 then Hyper_new1 = 100; 
	if Hyper_new = 0 then Hyper_new1 = 0; 
	
/*lasting use*/
if (mean_sbp >= 140 or mean_dbp >= 90 or bpq050a = 1) then do;
    Hyper_old = 1;
if (mean_sbp >= 140 or mean_dbp >= 90) then Controlold = 0;
      else if (n_sbp > 0 and n_dbp > 0) then Controlold = 1;
end;
  else if (n_sbp > 0 and n_dbp > 0) then
    Hyper_old = 0;

	if Hyper_old = 1 then Hyper_old1 = 100; 
	if Hyper_old = 0 then Hyper_old1 = 0; 


***aware**********************************************************************;
if bpq020=1 then aware=1;
else if bpq020=2 then aware=0;


*sex;
sex=RIAGENDR;

*Sub-population of interest;
if ridageyr >=18 and ridexprg ne 1 and (n_sbp ne 0 or n_dbp ne 0) then sela=1; 
if ridageyr >=20 and ridexprg ne 1 and (n_sbp ne 0 or n_dbp ne 0) then sela1=1; 

format agecat agecatfmt. sex sexfmt. race_et4 race_et4fmt.;

run;

data hyper1718_new;
set hyper1718;
* BROOKE ADDED: Create highSBP category variable;
	  if (mean_sbp >= 115 & n_sbp > 0) then highsbp_rate = 1;
	  if (mean_sbp < 115 & n_sbp > 0) then highsbp_rate = 0;

	  if highsbp_rate = 1 then highsbp_rate1 = 100;
	  if highsbp_rate = 0 then highsbp_rate1 = 0;
run;

data hyper1718_new;
set hyper1718_new;
if sex=2 then n2=0 ; * female;
if sex=1 then n2=4  ; * male;
if race_et4=1 then n3=1;
if race_et4=2 then n3=2;
if race_et4=3 then n3=3;
if race_et4=4 then n3=4;
if agecat=1 then n1=0; 	*age2034;
if agecat=2 then  n1=8; 	*age3544;
if agecat=3 then  n1=16;	*age4554;
if agecat=4 then  n1=24; 	*age5564;
if agecat=5 then  n1=32;	*age6574;
if agecat=6 then  n1=40; 	*age>74;
subgroup_id=n1+n2+n3 ; 
run;

data hyper1718adult;set hyper1718_new;where subgroup_id <>.;
run;


proc sort data=hyper1718adult;by subgroup_id;run;

ods output OneWay=B;
proc surveyfreq data=hyper1718adult;
tables highsbp_rate; *changed out this variable;
strata sdmvstra;
cluster sdmvpsu;
weight WTMEC2YR ; 
by subgroup_id;
run;

data SBPrate1718;set B;
where highsbp_rate=1;drop Table _SkipLine F_highsbp_rate;
run;


/*export dataset*/
proc export data=SBPrate1718
    outfile="C:\Users\bbell06\Box\lasting_aim_3\model development\data_new\in\SBP\highSBP_data.xlsx"
    dbms=xlsx
    replace;
    sheet="highSBP_by_subgroup";
run;

*SOURCE: SAS 9.4 Documentation SAS/STAT(R) 9.4 User's Guide

*Note: NOMCAR requests that the procedure treat missing values in the variance computation as not missing completely
at random (NOMCAR) for Taylor series variance estimation. When you specify the NOMCAR option, PROC SURVEYREG computes 
variance estimates by analyzing the nonmissing values as a domain or subpopulation, where the entire population includes
both nonmissing and missing domains. See the section Missing Values for more details. 
By default, PROC SURVEYREG completely excludes an observation from analysis if that observation has a missing value, 
unless you specify the MISSING option. Note that the NOMCAR option has no effect on a classification variable when you 
specify the MISSING option, which treats missing values as a valid nonmissing level. 
The NOMCAR option applies only to Taylor series variance estimation. The replication methods, which you request with the
VARMETHOD=BRR and VARMETHOD=JACKKNIFE options, do not use the NOMCAR option. 

*Note: that when there is a CLASS statement, you need to use the SOLUTION option with the CLPARM option to
obtain the parameter estimates and their confidence limits. 
VADJUST=DF | NONE 
specifies whether to use degrees of freedom adjustment  in the computation of the matrix  for the variance estimation. 
If you do not specify the VADJUST= option, by default, PROC SURVEYREG uses the degrees-of-freedom adjustment that is 
equivalent to the VARADJ=DF option. If you do not want to use this variance adjustment, you can specify the 
VADJUST=NONE option. ;

