filename in1 'stomache2018_1116.txt';

data stomach;
  /*NOTE: The data file was created using the Windows format line delimiter.*/
  /*The TERMSTR=CRLF input option for reading the file in UNIX, requires SAS version 9.*/
  infile in1 dsd LRECL = 32000 delimiter = '09'X TERMSTR = CRLF;

  length RaceandoriginrecodeNHWNHBNHOHis $20
    Sex $15
    Age_recode_10yr $11
    stomach $17
    ;
  /*NOTE: skipping over field names*/
  if _N_ = 1 then input;
  input RaceandoriginrecodeNHWNHBNHOHis $
    Sex $
    Age_recode_10yr $
    stomach $
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
    stomach = "stomach"
    Crude_Rate = "Crude Rate"
    Standard_Error = "Standard Error"
    Lower_Confidence_Interval = "Lower Confidence Interval"
    Upper_Confidence_Interval = "Upper Confidence Interval"
    Count = "Count"
    Population = "Population"
    ;
run;

