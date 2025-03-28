filename in1 'C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Cancer incidence\rawdata\cancerrate_wide2018_0213.txt';
libname RAWDATA "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Cancer incidence\rawdata";

data ratedat;
  /*NOTE: The data file was created using the Windows format line delimiter.*/
  /*The TERMSTR=CRLF input option for reading the file in UNIX, requires SAS version 9.*/
  infile in1 dsd LRECL = 32000 delimiter = '09'X TERMSTR = CRLF;

  length RaceandoriginrecodeNHWNHBNHOHis $20
    Sex $15
    Age_recode_10yr $11
    cancer_code_ICD_O_3 $36
    ;
  input RaceandoriginrecodeNHWNHBNHOHis $
    Sex $
    Age_recode_10yr $
    cancer_code_ICD_O_3 $
    Crude_Rate
    Standard_Error
    Lower_Confidence_Interval
    Upper_Confidence_Interval
    Count
    Population
    ;
  label RaceandoriginrecodeNHWNHBNHOHis = "Race and origin recode (NHW, NHB, NHO, Hispanic)"
    Sex = "Sex"
    Age_recode_10yr = "Age recode 10yr"
    cancer_code_ICD_O_3 = "cancer code ICD-O-3"
    Crude_Rate = "Crude Rate"
    Standard_Error = "Standard Error"
    Lower_Confidence_Interval = "Lower Confidence Interval"
    Upper_Confidence_Interval = "Upper Confidence Interval"
    Count = "Count"
    Population = "Population"
    ;
run;

data rawdata.cancer;set ratedat;run;
