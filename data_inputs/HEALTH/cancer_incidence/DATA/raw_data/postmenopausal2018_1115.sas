filename in1 'postmenopausal2018_1115.txt';

data ratedat;
  /*NOTE: The data file was created using the Windows format line delimiter.*/
  /*The TERMSTR=CRLF input option for reading the file in UNIX, requires SAS version 9.*/
  infile in1 dsd LRECL = 32000 delimiter = '09'X TERMSTR = CRLF;

  length RaceandoriginrecodeNHWNHBNHOHis $20
    Age_10yr_single_ages $11
    Sex $15
    BREAST $6
    ;
  /*NOTE: skipping over field names*/
  if _N_ = 1 then input;
  input RaceandoriginrecodeNHWNHBNHOHis $
    Age_10yr_single_ages $
    Sex $
    BREAST $
    Crude_Rate
    Standard_Error
    Lower_Confidence_Interval
    Upper_Confidence_Interval
    Count
    Population
    ;
  label RaceandoriginrecodeNHWNHBNHOHis = "Race and origin recode (NHW, NHB, NHO, Hispanic)"
    Age_10yr_single_ages = "Age 10yr single ages"
    Sex = "Sex"
    BREAST = "BREAST"
    Crude_Rate = "Crude Rate"
    Standard_Error = "Standard Error"
    Lower_Confidence_Interval = "Lower Confidence Interval"
    Upper_Confidence_Interval = "Upper Confidence Interval"
    Count = "Count"
    Population = "Population"
    ;
run;

