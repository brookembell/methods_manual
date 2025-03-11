
options nofmterr;
libname DATASET 'C:\Users\lwang18\Box\lasting_aim_3\data\in\Dietary inputs\Raw data';   
%let home=C:\Users\lwang18\Box\lasting_aim_3\data\in\Food prices ; 
 
****The price data prides the  food price per 100 grams of a FoodCode ****;
PROC IMPORT OUT= WORK.Price1516 
            DATAFILE= "&home\Raw data\NHANES Foods National Average Prices_InfoScan only.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="NHANES1516_IRI2015_2016_retail$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;
 
data price1516 ; set price1516; if FOODCode ne . ; run; 
***FPED prides the content of each food group(in servings, cups, or oz equi) per 100 grams of a FoodCode;

data FPED1516;
set DATASET.fped_1516  ;
/*rename variable to be consistent with previous analysis **/
rename V_DRKGR =veg_dg ; 
rename V_REDOR_TOTAL =veg_ro ; 
rename V_LEGUMES =veg_leg ; 
rename V_STARCHY_TOTAL =veg_sta ; 
rename V_OTHER =veg_oth ; 
rename F_TOTAL =fruit ;
rename G_WHOLE= gr_whole ; 
rename G_REFINED= gr_refined ; 
rename D_TOTAL= dairy ; 
rename PF_MEAT= pf_redm ; 
rename PF_CUREDMEAT= pf_pm ; 
rename PF_NUTSDS= pf_ns ; 
rename PF_LEGUMES= pf_leg ; 
rename PF_POULT= pf_POULTRY ; 
rename PF_EGGS= pf_EGG ; 
pf_seafood=sum(PF_SEAFD_HI, PF_SEAFD_LOW) ; 
rename oils= oil; 
run ;

*combine FPED and Price data ***; 

proc sql ; create table FPEDprice1516 as select 
* from price1516 as a left join FPED1516 as b on a.Foodcode=b.Foodcode  ; 
quit ; 

*Estimate intake for each Foodcode, as the weighting factor ; 
data DR1iff_i ; 
set DATASET.DR1iff_i ;
keep dr1iFDCD dr1igrms ;
rename dr1igrms=dr12igrms ; 
rename dr1iFDCD=FoodCode ; 
run; 

data DR2iff_i ; 
set DATASET.DR2iff_i ;
keep dr2iFDCD dr2igrms ;
rename dr2igrms=dr12igrms ; 
rename dr2iFDCD=FoodCode ; 
run; 

data D12iff ; 
set DR1iff_i  DR2iff_i ;
run; 
proc sort data=D12iff ;
by Foodcode  ; 
run; 

proc sql ; create table FCintake as select Foodcode,
sum(dr12igrms) as FCgrm from D12iff group by Foodcode ; 
quit ;

***Combine weighting factor with FPED-PRICE data ; 

proc sql ; create table FPEDprice1516a as select 
* from FPEDprice1516 as a left join FCintake as b on a.Foodcode=b.Foodcode  ; 
quit ; 

proc sql ; create table FPEDprice1516b as select 
* from FCintake  as a left join FPEDprice1516 as b on a.Foodcode=b.Foodcode  ; 
quit ; 



***Using the cotent of FPED food group in 100 grams of each FoodCode to predict the price of 100 grams of a FoodCode.
The coeffecient will represent the unit price for each FPED food group ***; 
ods output ParameterEstimates=Priceest ; 
proc reg data=FPEDprice1516a ;
model price_100gm=veg_dg veg_ro veg_leg veg_sta veg_oth fruit gr_whole gr_refined dairy pf_redm pf_pm pf_poultry 
pf_egg pf_seafood pf_ns pf_soy oil add_sugars solid_fats/NOINT; /**no interaction*/ 
weight FCgrm; 
quit ;  
ods close ; 

**the dataset Priceest contains the unit price estimate for each FPED group ; 

data  Priceest ; set Priceest  ; 
rename estimate=unitprice ; 
rename stderr=unitprice_se  ;
variable=lowcase(variable);
drop probt tvalue DF Model dependent; run; 
PROC EXPORT DATA= WORK.Priceest  
            OUTFILE= "&home\Output data\Priceest.xls" 
            DBMS=EXCEL REPLACE;
     SHEET="aa"; 
RUN;


