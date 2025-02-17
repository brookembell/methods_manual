libname RAWDATA "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\\Cancer incidence\rawdata";
libname CANCER "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\\Cancer incidence\input";
filename in1 'cancerrate2018_1109.txt';

proc format;
  value Age_recode_10yrf
    0 = "25-34 years"
    1 = "35-44 years"
    2 = "45-54 years"
    3 = "55-64 years"
    4 = "65-74 years"
    5 = "75+ years"
    ;
  value RaceandoriginrecodeNHWNHBNHOHisf
    0 = "Non-Hispanic White"
    1 = "Non-Hispanic Black"
    2 = "Hispanic (All Races)"
    3 = "OTHER"
    ;
  value Sexf
    0 = "Male and female"
    1 = "  Male"
    2 = "  Female"
    ;
  value cancer_code_ICD_O_3f
    0 = "All Sites"
    1 = "    Colon and Rectum"
    2 = "      Corpus Uteri"
    3 = "    Esophagus"
    4 = "  Breast"
    5 = "    Gallbladder"
    6 = "    Kidney and Renal Pelvis"
    7 = "Myeloma+myeloid&monocytic leukemia"
    8 = "oral cavity and pharynx and larynx"
    9 = "    Liver and Intrahepatic Bile Duct"
    10 = "    Lung and Bronchus"
    11 = "    Pancreas"
    12 = "    Ovary"
    13 = "    Prostate"
    14 = "    Stomach"
    15 = "    Thyroid"
    16 = "  Brain and Other Nervous System"
    ;
run;

data RAWDATA.cancerrate_2018_1109;
  /*NOTE: The data file was created using the Windows format line delimiter.*/
  /*The TERMSTR=CRLF input option for reading the file in UNIX, requires SAS version 9.*/
  infile in1 LRECL = 32000 delimiter = '09'X TERMSTR = CRLF;

  input Age_recode_10yr
    RaceandoriginrecodeNHWNHBNHOHis
    Sex
    cancer_code_ICD_O_3
    Crude_Rate
    Standard_Error
    Lower_Confidence_Interval
    Upper_Confidence_Interval
    Count
    Population
    ;
  label Age_recode_10yr = "Age recode 10yr"
    RaceandoriginrecodeNHWNHBNHOHis = "Race and origin recode (NHW, NHB, NHO, Hispanic)"
    Sex = "Sex"
    cancer_code_ICD_O_3 = "cancer code ICD-O-3"
    Crude_Rate = "Crude Rate"
    Standard_Error = "Standard Error"
    Lower_Confidence_Interval = "Lower Confidence Interval"
    Upper_Confidence_Interval = "Upper Confidence Interval"
    Count = "Count"
    Population = "Population"
    ;
  format Age_recode_10yr Age_recode_10yrf.
    RaceandoriginrecodeNHWNHBNHOHis RaceandoriginrecodeNHWNHBNHOHisf.
    Sex Sexf.
    cancer_code_ICD_O_3 cancer_code_ICD_O_3f.
    ;
run;


data RATERAW;set RAWDATA.cancerrate_2018_1109;where sex<>0;
if sex=2 then gender=1;/*F*/
if sex=1 then gender=2;/*M*/
if Age_recode_10yr=0 then n1=0; 	*age2534;
if Age_recode_10yr=1 then  n1=8; 	*age3544;
if Age_recode_10yr=2 then  n1=16;	*age4554;
if Age_recode_10yr=3 then  n1=24; 	*age5564;
if Age_recode_10yr=4 then  n1=32;	*age6574;
if Age_recode_10yr=5 then  n1=40; 	*age>74;
if gender=1 then n2=0; * female;
if gender=2 then n2=4; * male;
if RaceandoriginrecodeNHWNHBNHOHis=0 then n3=1 ;*nhw; 
if RaceandoriginrecodeNHWNHBNHOHis=1 then n3=2 ; *nhb;
if RaceandoriginrecodeNHWNHBNHOHis=2 then n3=3 ; *his;
if RaceandoriginrecodeNHWNHBNHOHis=3 then n3=4 ; *oth;
subgroup_id=n1+n2+n3 ; 
rename n3=racecat ; 
rename n1=agecat ; 
rename n2=sexcat;
rename gender=genderraw;
run;
data RATEGRP;set RATERAW;
length age $ 12 race $ 8 gender $ 6 cancer $ 48;
if Age_recode_10yr=0 then  age="25-34 years" ;
if Age_recode_10yr=1 then age="35-44 years" ;
if Age_recode_10yr=2 then  age="45-54 years" ;
if Age_recode_10yr=3 then  age="55-64 years" ;
if Age_recode_10yr=4 then  age="65-74 years" ;
if Age_recode_10yr=5 then  age="75+ years" ;
if sexcat=0 then gender="female"; * female;
if sexcat=4 then gender="male"; * male;
if racecat=1 then race="NHW";*nhw; 
if racecat=2 then race="NHB"; *nhb;
if racecat=3 then race="HIS"; *his;
if racecat=4 then race="OTH"; *oth;
length grp $48;grp=trim(age)||" "||trim(gender) ||" "||trim(race);
if cancer_code_ICD_O_3=0 then cancer= "All Sites";
if cancer_code_ICD_O_3=1 then cancer= "    Colon and Rectum";
if cancer_code_ICD_O_3=2 then cancer= "      Corpus Uteri";
if cancer_code_ICD_O_3=3 then cancer= "    Esophagus";
if cancer_code_ICD_O_3=4 then cancer= "  Breast";
if cancer_code_ICD_O_3=5 then cancer= "    Gallbladder";
if cancer_code_ICD_O_3=  6 then cancer= "    Kidney and Renal Pelvis";
if cancer_code_ICD_O_3=  7 then cancer= "Myeloma+myeloid&monocytic leukemia";
if cancer_code_ICD_O_3=  8 then cancer= "oral cavity and pharynx and larynx";
if cancer_code_ICD_O_3=  9 then cancer= "    Liver and Intrahepatic Bile Duct";
if cancer_code_ICD_O_3=  10 then cancer= "    Lung and Bronchus";
if cancer_code_ICD_O_3=  11 then cancer= "    Pancreas";
if cancer_code_ICD_O_3=  12 then cancer= "    Ovary";
if cancer_code_ICD_O_3=  13 then cancer= "    Prostate";
if cancer_code_ICD_O_3=  14 then cancer= "    Stomach";
if cancer_code_ICD_O_3=  15 then cancer= "    Thyroid";
if cancer_code_ICD_O_3=  16 then cancer = "  Brain and Other Nervous System";
run;

proc sort data=rategrp;by subgroup_id;run;
