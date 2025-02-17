libname cancer "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Cancer incidence\DATA";
%let home =C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Cancer incidence\DATA ;
/*proc import datafile="&home\2018CANCERRATE_0327.xlsx"
out=cancer18
dbms=xlsx replace; 
sheet="2018pop";
run;

data cancer.cancer18;set cancer18;run;
data cancer.cancer13;set cancer13;run;*/

data cancernew;set cancer18;
rename cancer_code_ICD_O_3= 
