proc format;
value agef
	0	=	"0-1"
	1   =   "2-5"
	2   =   "6-11"
	3   =   "12-19"
	4   =   "20-44"
	5 =  "45-54"
	6 =  "55-64"
 	7 = "65+";
	run;

proc format;
value riagendrf
 1="Male"
 2="Female";
 
run; 
proc format;
value racef
	1	=	"non-Hispanic white"
	2   =   "non-Hispanic black"
	3 =  "Hispanic"
	4 =  "Other"
 	;
	run;

proc format;
value eduf
	1	=	"Lower than secondary school"
	2   =   "High school or GED"
	3 =  "Some college or above"
 	;
	run;

proc format;
value peduf
	1	=	"Lower than secondary school"
	2   =   "High school or GED"
	3 =  "Some college or above"
 	;
	run;

proc format;
value pirf
	1	=	"Income to poverty ratio <1.3"
	2   =   "1.3<=Income to poverty ratio <3"
	3 =  "3<=Income to poverty ratio"
 	;
	run;

/***1.	Read in data *****/

/**/
libname lasting "C:\Users\bbell06\Box\lasting_aim_3\paper_costing1\data";

%let home =C:\Users\bbell06\Box\lasting_aim_3\paper_costing1\data ;

/*NHANES*/
/*1314*/
data nhanes1314d1 (rename=(DR1IFDCD=foodcode));
set lasting.dr1iff_h;
where  DR1DRSTZ=1;
/*limit to store food only */
/*where DR1FS= 1 ;*/
run; 


/*NHANES TO FCID LINKAGE*/
PROC IMPORT OUT= fcid 
            DATAFILE= "C:\Users\bbell06\Box\lasting_aim_3\data\in\Food waste\FCID_0118_LASTING.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

/*FOOD WASTE DATA*/
PROC IMPORT OUT= foodwaste 
            DATAFILE= "C:\Users\bbell06\Box\lasting_aim_3\data\in\Food waste\losswaste.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;


/*2.	Merge NHANES data with FCID_0118_LASTING.dta. by  foodcode, this disaggregates each food to FCID ingredient level. */

proc sql; 
  create table nhanes1314_fcid as
  select  SEQN, WTDRD1, WTDR2D, DR1IGRMS, fcid.foodcode, fcid.food_desc, fcid.fcidcode, fcid.fcid_desc, fcid.wt
  from nhanes1314d1,fcid
  where nhanes1314d1.foodcode=fcid.foodcode
  order by nhanes1314d1.SEQN;
quit
;

/*3.	Calculate FCID level weight*/
/*current wt variable is FCID gram per 100 gram of food code*/
/*therefore to calculate FCID grams: DR1IGRMS*wt/100=FCID grams */
data nhanes1314_fcid;
set nhanes1314_fcid;
fcid_gram=DR1IGRMS*wt/100;
run;

/*4.	Merge losswaste.dta via fcidcode*/
proc sql; 
  create table nhanes1314_fcid_foodwaste as
  select  *
  from nhanes1314_fcid,foodwaste
  where nhanes1314_fcid.fcidcode=foodwaste.fcidcode
  order by nhanes1314_fcid.SEQN;
quit;

/*5.	Calculate amount (g) of food wasted: waste_amount= DR1IGRMS*waste_coef
And calculate proportion of food waste: amount of food waste out of amount of edible portion
*/
data foodwaste_1314;
set nhanes1314_fcid_foodwaste;
waste_amount=fcid_gram*waste_coef;
ined_amount=fcid_gram*ined_coef;
ed_amount=waste_amount+fcid_gram;
pur_amount=ed_amount+ined_amount;
run;


/*6.	Group by DGA food group*/



data foodwaste_dga;
length food_group $15;
set foodwaste_1314;
if FCIDCode=	101050000	then food_group = 	"veg_ro";
else if FCIDCode=	101050001	then food_group = 	"babyfood";
else if FCIDCode=	101052000	then food_group = 	"added_sugar";
else if FCIDCode=	101052001	then food_group = 	"babyfood";
else if FCIDCode=	101053000	then food_group = 	"added_sugar";
else if FCIDCode=	101053001	then food_group = 	"babyfood";
else if FCIDCode=	101067000	then food_group = 	"veg_sta";
else if FCIDCode=	101078000	then food_group = 	"veg_ro";
else if FCIDCode=	101078001	then food_group = 	"babyfood";
else if FCIDCode=	101079000	then food_group = 	"veg_ro";
else if FCIDCode=	101084000	then food_group = 	"veg_oth";
else if FCIDCode=	101100000	then food_group = 	"veg_oth";
else if FCIDCode=	101168000	then food_group = 	"veg_oth";
else if FCIDCode=	101190000	then food_group = 	"veg_oth";
else if FCIDCode=	101250000	then food_group = 	"veg_oth";
else if FCIDCode=	101251000	then food_group = 	"veg_oth";
else if FCIDCode=	101251001	then food_group = 	"babyfood";
else if FCIDCode=	101314000	then food_group = 	"veg_oth";
else if FCIDCode=	101316000	then food_group = 	"veg_oth";
else if FCIDCode=	101327000	then food_group = 	"veg_oth";
else if FCIDCode=	101331000	then food_group = 	"veg_oth";
else if FCIDCode=	101388000	then food_group = 	"veg_oth";
else if FCIDCode=	103015000	then food_group = 	"veg_sta";
else if FCIDCode=	103015001	then food_group = 	"babyfood";
else if FCIDCode=	103017000	then food_group = 	"veg_oth";
else if FCIDCode=	103082000	then food_group = 	"veg_sta";
else if FCIDCode=	103082001	then food_group = 	"babyfood";
else if FCIDCode=	103139000	then food_group = 	"veg_sta";
else if FCIDCode=	103166000	then food_group = 	"veg_oth";
else if FCIDCode=	103166001	then food_group = 	"babyfood";
else if FCIDCode=	103167000	then food_group = 	"veg_oth";
else if FCIDCode=	103296000	then food_group = 	"veg_sta";
else if FCIDCode=	103297000	then food_group = 	"veg_sta";
else if FCIDCode=	103297001	then food_group = 	"babyfood";
else if FCIDCode=	103298000	then food_group = 	"veg_sta";
else if FCIDCode=	103298001	then food_group = 	"babyfood";
else if FCIDCode=	103299000	then food_group = 	"veg_sta";
else if FCIDCode=	103299001	then food_group = 	"babyfood";
else if FCIDCode=	103300000	then food_group = 	"veg_sta";
else if FCIDCode=	103300001	then food_group = 	"babyfood";
else if FCIDCode=	103366000	then food_group = 	"veg_sta";
else if FCIDCode=	103366001	then food_group = 	"babyfood";
else if FCIDCode=	103371000	then food_group = 	"veg_sta";
else if FCIDCode=	103387000	then food_group = 	"veg_oth";
else if FCIDCode=	103406000	then food_group = 	"veg_sta";
else if FCIDCode=	103407000	then food_group = 	"veg_sta";
else if FCIDCode=	200051000	then food_group = 	"veg_dg";
else if FCIDCode=	200101000	then food_group = 	"veg_oth";
else if FCIDCode=	200140000	then food_group = 	"veg_oth";
else if FCIDCode=	200317000	then food_group = 	"veg_oth";
else if FCIDCode=	200332000	then food_group = 	"veg_oth";
else if FCIDCode=	301165000	then food_group = 	"veg_oth";
else if FCIDCode=	301165001	then food_group = 	"babyfood";
else if FCIDCode=	301237000	then food_group = 	"veg_oth";
else if FCIDCode=	301237001	then food_group = 	"babyfood";
else if FCIDCode=	301238000	then food_group = 	"veg_oth";
else if FCIDCode=	301238001	then food_group = 	"babyfood";
else if FCIDCode=	301338000	then food_group = 	"veg_oth";
else if FCIDCode=	302103000	then food_group = 	"veg_oth";
else if FCIDCode=	302198000	then food_group = 	"veg_oth";
else if FCIDCode=	302239000	then food_group = 	"veg_oth";
else if FCIDCode=	302338500	then food_group = 	"veg_oth";
else if FCIDCode=	401005000	then food_group = 	"veg_dg";
else if FCIDCode=	401104000	then food_group = 	"veg_dg";
else if FCIDCode=	401118000	then food_group = 	"veg_dg";
else if FCIDCode=	401118001	then food_group = 	"babyfood";
else if FCIDCode=	401138000	then food_group = 	"veg_oth";
else if FCIDCode=	401144000	then food_group = 	"veg_oth";
else if FCIDCode=	401150000	then food_group = 	"veg_dg";
else if FCIDCode=	401204000	then food_group = 	"veg_oth";
else if FCIDCode=	401205000	then food_group = 	"veg_oth";
else if FCIDCode=	401248000	then food_group = 	"veg_dg";
else if FCIDCode=	401313000	then food_group = 	"veg_oth";
else if FCIDCode=	401355000	then food_group = 	"veg_dg";
else if FCIDCode=	401355001	then food_group = 	"babyfood";
else if FCIDCode=	401367000	then food_group = 	"veg_dg";
else if FCIDCode=	402018000	then food_group = 	"veg_dg";
else if FCIDCode=	402062000	then food_group = 	"veg_dg";
else if FCIDCode=	402063000	then food_group = 	"veg_dg";
else if FCIDCode=	402070000	then food_group = 	"veg_dg";
else if FCIDCode=	402117000	then food_group = 	"veg_dg";
else if FCIDCode=	402133000	then food_group = 	"veg_dg";
else if FCIDCode=	402134000	then food_group = 	"veg_dg";
else if FCIDCode=	402194000	then food_group = 	"veg_dg";
else if FCIDCode=	402229000	then food_group = 	"veg_dg";
else if FCIDCode=	402315000	then food_group = 	"veg_dg";
else if FCIDCode=	402318000	then food_group = 	"veg_dg";
else if FCIDCode=	402389000	then food_group = 	"veg_dg";
else if FCIDCode=	402398000	then food_group = 	"veg_dg";
else if FCIDCode=	500061000	then food_group = 	"veg_dg";
else if FCIDCode=	500061001	then food_group = 	"babyfood";
else if FCIDCode=	500064000	then food_group = 	"veg_dg";
else if FCIDCode=	500069000	then food_group = 	"veg_dg";
else if FCIDCode=	500071000	then food_group = 	"veg_dg";
else if FCIDCode=	500072000	then food_group = 	"veg_dg";
else if FCIDCode=	500083000	then food_group = 	"veg_dg";
else if FCIDCode=	600347000	then food_group = 	"pf_soy";
else if FCIDCode=	600348000	then food_group = 	"pf_soy";
else if FCIDCode=	600348001	then food_group = 	"babyfood";
else if FCIDCode=	600349000	then food_group = 	"pf_soy";
else if FCIDCode=	600349001	then food_group = 	"babyfood";
else if FCIDCode=	600350000	then food_group = 	"oil";
else if FCIDCode=	600350001	then food_group = 	"babyfood";
else if FCIDCode=	601043000	then food_group = 	"veg_leg";
else if FCIDCode=	601043001	then food_group = 	"babyfood";
else if FCIDCode=	601257000	then food_group = 	"veg_leg";
else if FCIDCode=	601349500	then food_group = 	"veg_leg";
else if FCIDCode=	602031000	then food_group = 	"veg_leg";
else if FCIDCode=	602033000	then food_group = 	"veg_leg";
else if FCIDCode=	602037000	then food_group = 	"veg_leg";
else if FCIDCode=	602255000	then food_group = 	"veg_leg";
else if FCIDCode=	602255001	then food_group = 	"babyfood";
else if FCIDCode=	602259000	then food_group = 	"veg_leg";
else if FCIDCode=	603030000	then food_group = 	"veg_leg";
else if FCIDCode=	603032000	then food_group = 	"veg_leg";
else if FCIDCode=	603034000	then food_group = 	"veg_leg";
else if FCIDCode=	603035000	then food_group = 	"veg_leg";
else if FCIDCode=	603036000	then food_group = 	"veg_leg";
else if FCIDCode=	603038000	then food_group = 	"veg_leg";
else if FCIDCode=	603039000	then food_group = 	"veg_leg";
else if FCIDCode=	603040000	then food_group = 	"veg_leg";
else if FCIDCode=	603041000	then food_group = 	"veg_leg";
else if FCIDCode=	603042000	then food_group = 	"veg_leg";
else if FCIDCode=	603098000	then food_group = 	"veg_leg";
else if FCIDCode=	603098001	then food_group = 	"babyfood";
else if FCIDCode=	603099000	then food_group = 	"veg_leg";
else if FCIDCode=	603182000	then food_group = 	"veg_leg";
else if FCIDCode=	603182001	then food_group = 	"babyfood";
else if FCIDCode=	603203000	then food_group = 	"veg_leg";
else if FCIDCode=	603256000	then food_group = 	"veg_leg";
else if FCIDCode=	603256001	then food_group = 	"babyfood";
else if FCIDCode=	603258000	then food_group = 	"veg_leg";
else if FCIDCode=	801173500	then food_group = 	"fruit";
else if FCIDCode=	801374000	then food_group = 	"fruit";
else if FCIDCode=	801375000	then food_group = 	"veg_ro";
else if FCIDCode=	801375001	then food_group = 	"babyfood";
else if FCIDCode=	801376000	then food_group = 	"veg_ro";
else if FCIDCode=	801376001	then food_group = 	"babyfood";
else if FCIDCode=	801377000	then food_group = 	"veg_ro";
else if FCIDCode=	801377001	then food_group = 	"babyfood";
else if FCIDCode=	801378000	then food_group = 	"veg_ro";
else if FCIDCode=	801378001	then food_group = 	"babyfood";
else if FCIDCode=	801379000	then food_group = 	"veg_ro";
else if FCIDCode=	801380000	then food_group = 	"veg_ro";
else if FCIDCode=	802148000	then food_group = 	"veg_oth";
else if FCIDCode=	802234000	then food_group = 	"veg_oth";
else if FCIDCode=	802270000	then food_group = 	"veg_ro";
else if FCIDCode=	802270001	then food_group = 	"babyfood";
else if FCIDCode=	802271000	then food_group = 	"veg_ro";
else if FCIDCode=	802271001	then food_group = 	"babyfood";
else if FCIDCode=	802272000	then food_group = 	"veg_oth";
else if FCIDCode=	802272001	then food_group = 	"babyfood";
else if FCIDCode=	802273000	then food_group = 	"veg_oth";
else if FCIDCode=	901075000	then food_group = 	"fruit";
else if FCIDCode=	901187000	then food_group = 	"fruit";
else if FCIDCode=	901399000	then food_group = 	"fruit";
else if FCIDCode=	901400000	then food_group = 	"fruit";
else if FCIDCode=	902021000	then food_group = 	"fruit";
else if FCIDCode=	902088000	then food_group = 	"fruit";
else if FCIDCode=	902102000	then food_group = 	"veg_oth";
else if FCIDCode=	902135000	then food_group = 	"veg_oth";
else if FCIDCode=	902308000	then food_group = 	"veg_ro";
else if FCIDCode=	902309000	then food_group = 	"pf_ns";
else if FCIDCode=	902356000	then food_group = 	"veg_sta";
else if FCIDCode=	902356001	then food_group = 	"babyfood";
else if FCIDCode=	902357000	then food_group = 	"veg_sta";
else if FCIDCode=	902357001	then food_group = 	"babyfood";
else if FCIDCode=	1001106000	then food_group = 	"fruit";
else if FCIDCode=	1001107000	then food_group = 	"fruit";
else if FCIDCode=	1001108000	then food_group = 	"oil";
else if FCIDCode=	1001240000	then food_group = 	"fruit";
else if FCIDCode=	1001241000	then food_group = 	"fruit";
else if FCIDCode=	1001241001	then food_group = 	"babyfood";
else if FCIDCode=	1001242000	then food_group = 	"fruit";
else if FCIDCode=	1001369000	then food_group = 	"fruit";
else if FCIDCode=	1001370000	then food_group = 	"fruit";
else if FCIDCode=	1002197000	then food_group = 	"fruit";
else if FCIDCode=	1002199000	then food_group = 	"fruit";
else if FCIDCode=	1002200000	then food_group = 	"fruit";
else if FCIDCode=	1002200001	then food_group = 	"babyfood";
else if FCIDCode=	1002201000	then food_group = 	"fruit";
else if FCIDCode=	1002206000	then food_group = 	"fruit";
else if FCIDCode=	1002207000	then food_group = 	"fruit";
else if FCIDCode=	1002207001	then food_group = 	"babyfood";
else if FCIDCode=	1003180000	then food_group = 	"fruit";
else if FCIDCode=	1003181000	then food_group = 	"fruit";
else if FCIDCode=	1003307000	then food_group = 	"fruit";
else if FCIDCode=	1100007000	then food_group = 	"fruit";
else if FCIDCode=	1100008000	then food_group = 	"fruit";
else if FCIDCode=	1100008001	then food_group = 	"babyfood";
else if FCIDCode=	1100009000	then food_group = 	"fruit";
else if FCIDCode=	1100009001	then food_group = 	"babyfood";
else if FCIDCode=	1100010000	then food_group = 	"fruit";
else if FCIDCode=	1100010001	then food_group = 	"babyfood";
else if FCIDCode=	1100011000	then food_group = 	"fruit";
else if FCIDCode=	1100011001	then food_group = 	"babyfood";
else if FCIDCode=	1100129000	then food_group = 	"fruit";
else if FCIDCode=	1100210000	then food_group = 	"fruit";
else if FCIDCode=	1100266000	then food_group = 	"fruit";
else if FCIDCode=	1100266001	then food_group = 	"babyfood";
else if FCIDCode=	1100267000	then food_group = 	"fruit";
else if FCIDCode=	1100268000	then food_group = 	"fruit";
else if FCIDCode=	1100268001	then food_group = 	"babyfood";
else if FCIDCode=	1100310000	then food_group = 	"fruit";
else if FCIDCode=	1201090000	then food_group = 	"fruit";
else if FCIDCode=	1201090001	then food_group = 	"babyfood";
else if FCIDCode=	1201091000	then food_group = 	"fruit";
else if FCIDCode=	1201091001	then food_group = 	"babyfood";
else if FCIDCode=	1202012000	then food_group = 	"fruit";
else if FCIDCode=	1202012001	then food_group = 	"babyfood";
else if FCIDCode=	1202013000	then food_group = 	"fruit";
else if FCIDCode=	1202014000	then food_group = 	"fruit";
else if FCIDCode=	1202014001	then food_group = 	"babyfood";
else if FCIDCode=	1202230000	then food_group = 	"fruit";
else if FCIDCode=	1202260000	then food_group = 	"fruit";
else if FCIDCode=	1202260001	then food_group = 	"babyfood";
else if FCIDCode=	1202261000	then food_group = 	"fruit";
else if FCIDCode=	1202261001	then food_group = 	"babyfood";
else if FCIDCode=	1202262000	then food_group = 	"fruit";
else if FCIDCode=	1202262001	then food_group = 	"babyfood";
else if FCIDCode=	1203285000	then food_group = 	"fruit";
else if FCIDCode=	1203285001	then food_group = 	"babyfood";
else if FCIDCode=	1203286000	then food_group = 	"fruit";
else if FCIDCode=	1203286001	then food_group = 	"babyfood";
else if FCIDCode=	1203287000	then food_group = 	"fruit";
else if FCIDCode=	1203287001	then food_group = 	"babyfood";
else if FCIDCode=	1203288000	then food_group = 	"fruit";
else if FCIDCode=	1203288001	then food_group = 	"babyfood";
else if FCIDCode=	1301055000	then food_group = 	"fruit";
else if FCIDCode=	1301056000	then food_group = 	"fruit";
else if FCIDCode=	1301056001	then food_group = 	"babyfood";
else if FCIDCode=	1301058000	then food_group = 	"fruit";
else if FCIDCode=	1301208000	then food_group = 	"fruit";
else if FCIDCode=	1301320000	then food_group = 	"fruit";
else if FCIDCode=	1301320001	then food_group = 	"babyfood";
else if FCIDCode=	1301321000	then food_group = 	"fruit";
else if FCIDCode=	1301321001	then food_group = 	"babyfood";
else if FCIDCode=	1302057000	then food_group = 	"fruit";
else if FCIDCode=	1302057001	then food_group = 	"babyfood";
else if FCIDCode=	1302136000	then food_group = 	"fruit";
else if FCIDCode=	1302137000	then food_group = 	"fruit";
else if FCIDCode=	1302149000	then food_group = 	"fruit";
else if FCIDCode=	1302174000	then food_group = 	"fruit";
else if FCIDCode=	1302191000	then food_group = 	"fruit";
else if FCIDCode=	1303227000	then food_group = 	"fruit";
else if FCIDCode=	1304175000	then food_group = 	"fruit";
else if FCIDCode=	1304176000	then food_group = 	"fruit";
else if FCIDCode=	1304176001	then food_group = 	"babyfood";
else if FCIDCode=	1304178000	then food_group = 	"fruit";
else if FCIDCode=	1304179000	then food_group = 	"other";
else if FCIDCode=	1304195000	then food_group = 	"fruit";
else if FCIDCode=	1307130000	then food_group = 	"fruit";
else if FCIDCode=	1307130001	then food_group = 	"babyfood";
else if FCIDCode=	1307131000	then food_group = 	"fruit";
else if FCIDCode=	1307132000	then food_group = 	"fruit";
else if FCIDCode=	1307132001	then food_group = 	"babyfood";
else if FCIDCode=	1307359000	then food_group = 	"fruit";
else if FCIDCode=	1307359001	then food_group = 	"babyfood";
else if FCIDCode=	1307360000	then food_group = 	"fruit";
else if FCIDCode=	1307360001	then food_group = 	"babyfood";
else if FCIDCode=	1400003000	then food_group = 	"pf_ns";
else if FCIDCode=	1400003001	then food_group = 	"babyfood";
else if FCIDCode=	1400004000	then food_group = 	"oil";
else if FCIDCode=	1400004001	then food_group = 	"babyfood";
else if FCIDCode=	1400059000	then food_group = 	"pf_ns";
else if FCIDCode=	1400068000	then food_group = 	"pf_ns";
else if FCIDCode=	1400081000	then food_group = 	"pf_ns";
else if FCIDCode=	1400092000	then food_group = 	"pf_ns";
else if FCIDCode=	1400111000	then food_group = 	"fruit";
else if FCIDCode=	1400111001	then food_group = 	"babyfood";
else if FCIDCode=	1400112000	then food_group = 	"fruit";
else if FCIDCode=	1400113000	then food_group = 	"fruit";
else if FCIDCode=	1400114000	then food_group = 	"oil";
else if FCIDCode=	1400114001	then food_group = 	"babyfood";
else if FCIDCode=	1400155000	then food_group = 	"pf_ns";
else if FCIDCode=	1400156000	then food_group = 	"oil";
else if FCIDCode=	1400185000	then food_group = 	"pf_ns";
else if FCIDCode=	1400213000	then food_group = 	"pf_ns";
else if FCIDCode=	1400269000	then food_group = 	"pf_ns";
else if FCIDCode=	1400278000	then food_group = 	"pf_ns";
else if FCIDCode=	1400282000	then food_group = 	"pf_ns";
else if FCIDCode=	1400391000	then food_group = 	"pf_ns";
else if FCIDCode=	1500025000	then food_group = 	"gr_whole";
else if FCIDCode=	1500025001	then food_group = 	"babyfood";
else if FCIDCode=	1500026000	then food_group = 	"gr_whole";
else if FCIDCode=	1500026001	then food_group = 	"babyfood";
else if FCIDCode=	1500027000	then food_group = 	"gr_whole";
else if FCIDCode=	1500065000	then food_group = 	"gr_whole";
else if FCIDCode=	1500066000	then food_group = 	"gr_whole";
else if FCIDCode=	1500120000	then food_group = 	"gr_refined";
else if FCIDCode=	1500120001	then food_group = 	"babyfood";
else if FCIDCode=	1500121000	then food_group = 	"gr_whole";
else if FCIDCode=	1500121001	then food_group = 	"babyfood";
else if FCIDCode=	1500122000	then food_group = 	"gr_whole";
else if FCIDCode=	1500123000	then food_group = 	"gr_refined";
else if FCIDCode=	1500123001	then food_group = 	"babyfood";
else if FCIDCode=	1500124000	then food_group = 	"added_sugar";
else if FCIDCode=	1500124001	then food_group = 	"babyfood";
else if FCIDCode=	1500125000	then food_group = 	"oil";
else if FCIDCode=	1500125001	then food_group = 	"babyfood";
else if FCIDCode=	1500126000	then food_group = 	"gr_whole";
else if FCIDCode=	1500127000	then food_group = 	"veg_sta"; *sweet corn: changed from whole grain to starchy vegetable on 9/22/22;
else if FCIDCode=	1500127001	then food_group = 	"babyfood";
else if FCIDCode=	1500226000	then food_group = 	"gr_whole";
else if FCIDCode=	1500231000	then food_group = 	"gr_whole";
else if FCIDCode=	1500232000	then food_group = 	"gr_whole";
else if FCIDCode=	1500232001	then food_group = 	"babyfood";
else if FCIDCode=	1500233000	then food_group = 	"gr_whole";
else if FCIDCode=	1500233001	then food_group = 	"babyfood";
else if FCIDCode=	1500323000	then food_group = 	"gr_refined";
else if FCIDCode=	1500323001	then food_group = 	"babyfood";
else if FCIDCode=	1500324000	then food_group = 	"gr_whole";
else if FCIDCode=	1500324001	then food_group = 	"babyfood";
else if FCIDCode=	1500325000	then food_group = 	"gr_refined";
else if FCIDCode=	1500325001	then food_group = 	"babyfood";
else if FCIDCode=	1500326000	then food_group = 	"gr_whole";
else if FCIDCode=	1500326001	then food_group = 	"babyfood";
else if FCIDCode=	1500328000	then food_group = 	"gr_whole";
else if FCIDCode=	1500329000	then food_group = 	"gr_whole";
else if FCIDCode=	1500344000	then food_group = 	"gr_whole";
else if FCIDCode=	1500345000	then food_group = 	"added_sugar";
else if FCIDCode=	1500381000	then food_group = 	"gr_whole";
else if FCIDCode=	1500381001	then food_group = 	"babyfood";
else if FCIDCode=	1500401000	then food_group = 	"gr_whole";
else if FCIDCode=	1500401001	then food_group = 	"babyfood";
else if FCIDCode=	1500402000	then food_group = 	"gr_refined";
else if FCIDCode=	1500402001	then food_group = 	"babyfood";
else if FCIDCode=	1500403000	then food_group = 	"gr_whole";
else if FCIDCode=	1500404000	then food_group = 	"gr_whole";
else if FCIDCode=	1500405000	then food_group = 	"gr_whole";
else if FCIDCode=	1800002000	then food_group = 	"veg_leg";
else if FCIDCode=	1901028000	then food_group = 	"veg_oth";
else if FCIDCode=	1901028001	then food_group = 	"babyfood";
else if FCIDCode=	1901029000	then food_group = 	"veg_oth";
else if FCIDCode=	1901029001	then food_group = 	"babyfood";
else if FCIDCode=	1901102500	then food_group = 	"veg_oth";
else if FCIDCode=	1901184000	then food_group = 	"veg_oth";
else if FCIDCode=	1901184001	then food_group = 	"babyfood";
else if FCIDCode=	1901202000	then food_group = 	"veg_oth";
else if FCIDCode=	1901220000	then food_group = 	"veg_oth";
else if FCIDCode=	1901220001	then food_group = 	"babyfood";
else if FCIDCode=	1901249000	then food_group = 	"veg_dg";
else if FCIDCode=	1901249001	then food_group = 	"babyfood";
else if FCIDCode=	1901334000	then food_group = 	"veg_oth";
else if FCIDCode=	1902105000	then food_group = 	"veg_oth";
else if FCIDCode=	1902105001	then food_group = 	"babyfood";
else if FCIDCode=	1902119000	then food_group = 	"veg_oth";
else if FCIDCode=	1902119001	then food_group = 	"babyfood";
else if FCIDCode=	1902143000	then food_group = 	"veg_oth";
else if FCIDCode=	1902274000	then food_group = 	"veg_oth";
else if FCIDCode=	1902274001	then food_group = 	"babyfood";
else if FCIDCode=	1902354000	then food_group = 	"veg_oth";
else if FCIDCode=	1902354001	then food_group = 	"babyfood";
else if FCIDCode=	2001162900	then food_group = 	"pf_ns";
else if FCIDCode=	2001163000	then food_group = 	"oil";
else if FCIDCode=	2001319000	then food_group = 	"oil";
else if FCIDCode=	2001319001	then food_group = 	"babyfood";
else if FCIDCode=	2001336000	then food_group = 	"pf_ns";
else if FCIDCode=	2001336001	then food_group = 	"babyfood";
else if FCIDCode=	2001337000	then food_group = 	"oil";
else if FCIDCode=	2001337001	then food_group = 	"babyfood";
else if FCIDCode=	2002330000	then food_group = 	"oil";
else if FCIDCode=	2002330001	then food_group = 	"babyfood";
else if FCIDCode=	2002364000	then food_group = 	"pf_ns";
else if FCIDCode=	2002365000	then food_group = 	"oil";
else if FCIDCode=	2002365001	then food_group = 	"babyfood";
else if FCIDCode=	2003128000	then food_group = 	"oil";
else if FCIDCode=	2003128001	then food_group = 	"babyfood";
else if FCIDCode=	2100228000	then food_group = 	"veg_oth";
else if FCIDCode=	2201001500	then food_group = 	"veg_dg";
else if FCIDCode=	2201019000	then food_group = 	"veg_dg";
else if FCIDCode=	2201022000	then food_group = 	"veg_dg";
else if FCIDCode=	2201073000	then food_group = 	"veg_dg";
else if FCIDCode=	2201087000	then food_group = 	"veg_dg";
else if FCIDCode=	2201152000	then food_group = 	"veg_dg";
else if FCIDCode=	2201196000	then food_group = 	"veg_dg";
else if FCIDCode=	2201243000	then food_group = 	"veg_dg";
else if FCIDCode=	2202076000	then food_group = 	"veg_dg";
else if FCIDCode=	2202085000	then food_group = 	"veg_oth";
else if FCIDCode=	2202085001	then food_group = 	"babyfood";
else if FCIDCode=	2202086000	then food_group = 	"veg_oth";
else if FCIDCode=	2202322000	then food_group = 	"veg_oth";
else if FCIDCode=	2301001000	then food_group = 	"fruit";
else if FCIDCode=	2301235000	then food_group = 	"fruit";
else if FCIDCode=	2301236000	then food_group = 	"oil";
else if FCIDCode=	2302077000	then food_group = 	"veg_leg";
else if FCIDCode=	2302153000	then food_group = 	"fruit";
else if FCIDCode=	2302154000	then food_group = 	"fruit";
else if FCIDCode=	2302183000	then food_group = 	"fruit";
else if FCIDCode=	2302183001	then food_group = 	"babyfood";
else if FCIDCode=	2302358000	then food_group = 	"fruit";
else if FCIDCode=	2302368000	then food_group = 	"fruit";
else if FCIDCode=	2303000500	then food_group = 	"fruit";
else if FCIDCode=	2303141000	then food_group = 	"fruit";
else if FCIDCode=	2303151000	then food_group = 	"fruit";
else if FCIDCode=	2401019500	then food_group = 	"fruit";
else if FCIDCode=	2401074000	then food_group = 	"fruit";
else if FCIDCode=	2401211000	then food_group = 	"fruit";
else if FCIDCode=	2401212000	then food_group = 	"fruit";
else if FCIDCode=	2401351000	then food_group = 	"fruit";
else if FCIDCode=	2402020000	then food_group = 	"fruit";
else if FCIDCode=	2402023000	then food_group = 	"fruit";
else if FCIDCode=	2402023001	then food_group = 	"babyfood";
else if FCIDCode=	2402024000	then food_group = 	"fruit";
else if FCIDCode=	2402024001	then food_group = 	"babyfood";
else if FCIDCode=	2402215000	then food_group = 	"fruit";
else if FCIDCode=	2402215001	then food_group = 	"babyfood";
else if FCIDCode=	2402216000	then food_group = 	"fruit";
else if FCIDCode=	2402217000	then food_group = 	"fruit";
else if FCIDCode=	2402217001	then food_group = 	"babyfood";
else if FCIDCode=	2402245000	then food_group = 	"fruit";
else if FCIDCode=	2402245001	then food_group = 	"babyfood";
else if FCIDCode=	2402246000	then food_group = 	"fruit";
else if FCIDCode=	2402247000	then food_group = 	"fruit";
else if FCIDCode=	2402254000	then food_group = 	"fruit";
else if FCIDCode=	2402277000	then food_group = 	"fruit";
else if FCIDCode=	2402283000	then food_group = 	"fruit";
else if FCIDCode=	2402284000	then food_group = 	"fruit";
else if FCIDCode=	2402289000	then food_group = 	"fruit";
else if FCIDCode=	2402290000	then food_group = 	"fruit";
else if FCIDCode=	2403060000	then food_group = 	"fruit";
else if FCIDCode=	2403089000	then food_group = 	"fruit";
else if FCIDCode=	2403193000	then food_group = 	"fruit";
else if FCIDCode=	2403209000	then food_group = 	"fruit";
else if FCIDCode=	2403214000	then food_group = 	"fruit";
else if FCIDCode=	2403279000	then food_group = 	"fruit";
else if FCIDCode=	2403279001	then food_group = 	"babyfood";
else if FCIDCode=	2403280000	then food_group = 	"fruit";
else if FCIDCode=	2403281000	then food_group = 	"fruit";
else if FCIDCode=	2403281001	then food_group = 	"babyfood";
else if FCIDCode=	2403333000	then food_group = 	"fruit";
else if FCIDCode=	2403346000	then food_group = 	"fruit";
else if FCIDCode=	2403361000	then food_group = 	"fruit";
else if FCIDCode=	2404050206	then food_group = 	"fruit";
else if FCIDCode=	2404062904	then food_group = 	"fruit";
else if FCIDCode=	2405252000	then food_group = 	"fruit";
else if FCIDCode=	2405252001	then food_group = 	"babyfood";
else if FCIDCode=	2405253000	then food_group = 	"fruit";
else if FCIDCode=	2405253001	then food_group = 	"babyfood";
else if FCIDCode=	3100044000	then food_group = 	"pf_rm";
else if FCIDCode=	3100044001	then food_group = 	"babyfood";
else if FCIDCode=	3100045000	then food_group = 	"pf_rm";
else if FCIDCode=	3100046000	then food_group = 	"pf_rm";
else if FCIDCode=	3100046001	then food_group = 	"babyfood";
else if FCIDCode=	3100047000	then food_group = 	"sat_fat";
else if FCIDCode=	3100047001	then food_group = 	"babyfood";
else if FCIDCode=	3100048000	then food_group = 	"pf_rm";
else if FCIDCode=	3100049000	then food_group = 	"pf_rm";
else if FCIDCode=	3100049001	then food_group = 	"babyfood";
else if FCIDCode=	3200169000	then food_group = 	"pf_rm";
else if FCIDCode=	3200170000	then food_group = 	"pf_rm";
else if FCIDCode=	3200171000	then food_group = 	"sat_fat";
else if FCIDCode=	3200172000	then food_group = 	"pf_rm";
else if FCIDCode=	3200173000	then food_group = 	"pf_rm";
else if FCIDCode=	3300189000	then food_group = 	"pf_rm";
else if FCIDCode=	3400290000	then food_group = 	"pf_rm";
else if FCIDCode=	3400290001	then food_group = 	"babyfood";
else if FCIDCode=	3400291000	then food_group = 	"pf_rm";
else if FCIDCode=	3400292000	then food_group = 	"pf_rm";
else if FCIDCode=	3400292001	then food_group = 	"babyfood";
else if FCIDCode=	3400293000	then food_group = 	"sat_fat";
else if FCIDCode=	3400293001	then food_group = 	"babyfood";
else if FCIDCode=	3400294000	then food_group = 	"pf_rm";
else if FCIDCode=	3400295000	then food_group = 	"pf_rm";
else if FCIDCode=	3500339000	then food_group = 	"pf_rm";
else if FCIDCode=	3500339001	then food_group = 	"babyfood";
else if FCIDCode=	3500340000	then food_group = 	"pf_rm";
else if FCIDCode=	3500341000	then food_group = 	"sat_fat";
else if FCIDCode=	3500341001	then food_group = 	"babyfood";
else if FCIDCode=	3500342000	then food_group = 	"pf_rm";
else if FCIDCode=	3500343000	then food_group = 	"pf_rm";
else if FCIDCode=	3600222000	then food_group = 	"sat_fat";
else if FCIDCode=	3600222001	then food_group = 	"babyfood";
else if FCIDCode=	3600223000	then food_group = 	"dairy";
else if FCIDCode=	3600223001	then food_group = 	"babyfood";
else if FCIDCode=	3600224000	then food_group = 	"dairy";
else if FCIDCode=	3600224001	then food_group = 	"babyfood";
else if FCIDCode=	3600225001	then food_group = 	"babyfood";
else if FCIDCode=	3700222501	then food_group = 	"babyfood";
else if FCIDCode=	3800221000	then food_group = 	"pf_rm";
else if FCIDCode=	3900312000	then food_group = 	"pf_rm";
else if FCIDCode=	4000093000	then food_group = 	"pf_poultry";
else if FCIDCode=	4000093001	then food_group = 	"babyfood";
else if FCIDCode=	4000094000	then food_group = 	"pf_poultry";
else if FCIDCode=	4000095000	then food_group = 	"pf_poultry";
else if FCIDCode=	4000095001	then food_group = 	"babyfood";
else if FCIDCode=	4000096000	then food_group = 	"pf_poultry";
else if FCIDCode=	4000096001	then food_group = 	"babyfood";
else if FCIDCode=	4000097000	then food_group = 	"pf_poultry";
else if FCIDCode=	4000097001	then food_group = 	"babyfood";
else if FCIDCode=	5000382000	then food_group = 	"pf_poultry";
else if FCIDCode=	5000382001	then food_group = 	"babyfood";
else if FCIDCode=	5000383000	then food_group = 	"pf_poultry";
else if FCIDCode=	5000383001	then food_group = 	"babyfood";
else if FCIDCode=	5000384000	then food_group = 	"pf_poultry";
else if FCIDCode=	5000384001	then food_group = 	"babyfood";
else if FCIDCode=	5000385000	then food_group = 	"pf_poultry";
else if FCIDCode=	5000385001	then food_group = 	"babyfood";
else if FCIDCode=	5000386000	then food_group = 	"pf_poultry";
else if FCIDCode=	5000386001	then food_group = 	"babyfood";
else if FCIDCode=	6000301000	then food_group = 	"pf_poultry";
else if FCIDCode=	6000302000	then food_group = 	"pf_poultry";
else if FCIDCode=	6000303000	then food_group = 	"pf_poultry";
else if FCIDCode=	6000304000	then food_group = 	"pf_poultry";
else if FCIDCode=	6000305000	then food_group = 	"pf_poultry";
else if FCIDCode=	7000145000	then food_group = 	"pf_egg";
else if FCIDCode=	7000145001	then food_group = 	"babyfood";
else if FCIDCode=	7000146000	then food_group = 	"pf_egg";
else if FCIDCode=	7000146001	then food_group = 	"babyfood";
else if FCIDCode=	7000147000	then food_group = 	"pf_egg";
else if FCIDCode=	7000147001	then food_group = 	"babyfood";
else if FCIDCode=	8000157000	then food_group = 	"pf_seafood";
else if FCIDCode=	8000158000	then food_group = 	"pf_seafood";
else if FCIDCode=	8000159000	then food_group = 	"pf_seafood";
else if FCIDCode=	8000160000	then food_group = 	"pf_seafood";
else if FCIDCode=	8000161000	then food_group = 	"pf_seafood";
else if FCIDCode=	8000162000	then food_group = 	"pf_seafood";
else if FCIDCode=	8601000000	then food_group = 	"water";
else if FCIDCode=	8601100000	then food_group = 	"water";
else if FCIDCode=	8601200000	then food_group = 	"water";
else if FCIDCode=	8601300000	then food_group = 	"water";
else if FCIDCode=	8601400000	then food_group = 	"water";
else if FCIDCode=	8602000000	then food_group = 	"water";
else if FCIDCode=	8602100000	then food_group = 	"water";
else if FCIDCode=	8602200000	then food_group = 	"water";
else if FCIDCode=	8602300000	then food_group = 	"water";
else if FCIDCode=	8602400000	then food_group = 	"water";
else if FCIDCode=	9500006000	then food_group = 	"gr_whole";
else if FCIDCode=	9500016000	then food_group = 	"veg_oth";
else if FCIDCode=	9500054000	then food_group = 	"veg_oth";
else if FCIDCode=	9500109000	then food_group = 	"other"; *cocoa bean, chocolate: changed from added_sugar to "other" on 9/22/22;
else if FCIDCode=	9500110000	then food_group = 	"other"; *cocoa bean, powder: changed from added_sugar to "other" on 9/22/22;
else if FCIDCode=	9500115000	then food_group = 	"coffee_tea";
else if FCIDCode=	9500116000	then food_group = 	"coffee_tea";
else if FCIDCode=	9500177000	then food_group = 	"veg_dg";
else if FCIDCode=	9500186000	then food_group = 	"added_sugar";
else if FCIDCode=	9500186001	then food_group = 	"babyfood";
else if FCIDCode=	9500186100	then food_group = 	"other";
else if FCIDCode=	9500188000	then food_group = 	"other";
else if FCIDCode=	9500218000	then food_group = 	"added_sugar";
else if FCIDCode=	9500219000	then food_group = 	"added_sugar";
else if FCIDCode=	9500244000	then food_group = 	"oil";
else if FCIDCode=	9500244001	then food_group = 	"babyfood";
else if FCIDCode=	9500263000	then food_group = 	"pf_ns";
else if FCIDCode=	9500264000	then food_group = 	"pf_ns";
else if FCIDCode=	9500265000	then food_group = 	"oil";
else if FCIDCode=	9500275000	then food_group = 	"veg_oth";
else if FCIDCode=	9500276000	then food_group = 	"oil";
else if FCIDCode=	9500306000	then food_group = 	"pf_ns";
else if FCIDCode=	9500311000	then food_group = 	"gr_whole";
else if FCIDCode=	9500335000	then food_group = 	"veg_oth";
else if FCIDCode=	9500335001	then food_group = 	"babyfood";
else if FCIDCode=	9500352000	then food_group = 	"veg_oth";
else if FCIDCode=	9500353000	then food_group = 	"veg_oth";
else if FCIDCode=	9500362000	then food_group = 	"added_sugar";
else if FCIDCode=	9500362001	then food_group = 	"babyfood";
else if FCIDCode=	9500363000	then food_group = 	"added_sugar";
else if FCIDCode=	9500363001	then food_group = 	"babyfood";
else if FCIDCode=	9500372000	then food_group = 	"coffee_tea";
else if FCIDCode=	9500373000	then food_group = 	"coffee_tea";
else if FCIDCode=	9500373500	then food_group = 	"gr_whole";
else if FCIDCode=	9500390000	then food_group = 	"other";
else if FCIDCode=	9500397000	then food_group = 	"veg_sta";
run;

proc sql;
create table coef as 
select DISTINCT(fcid_desc), food_group, waste_coef, ined_coef
from foodwaste_dga
order by waste_coef;
quit; 

* update 9/27/22 
1) change pumpkin seed to match pine nut (as proxy)
2) change popcorn to match field corn (as proxy)
3) change soy milk to match cows milk (as proxy);

data coef_new;
set coef;
if fcid_desc = "Pumpkin, seed" then waste_coef = 0.21951220929623; *pumpkin seed fcid=902309000;
if fcid_desc = "Pumpkin, seed" then ined_coef = 0; 
if fcid_desc = "Corn, pop" then waste_coef = 0.25; *popcorn fcid=1500126000;
if fcid_desc = "Corn, pop" then ined_coef = 0; 
if fcid_desc = "Soybean, soy milk" then waste_coef = 0.94491523504257; *sum of cow's milks two coefficients (0.69 + 0.25);
if fcid_desc = "Soybean, soy milk" then ined = 0;
run;

proc sort data=coef_new;
by fcid_desc; run;

ods excel file="C:\Users\bbell06\Box\lasting_aim_3\planning\Methods of estimating food waste and inedible portion\results\fcid_coef_%sysfunc(today(), mmddyyd10.).xlsx" 
options (sheet_name="ceof");

proc report data=coef_new;run;
ods excel close; 
 
/*7.	Using proc sql, sum waste_amount, and waste_portio by seqn*/
/*this would give the sum in grams for wasted amount per DGA food group per individual*/ 
proc sql;
    create table foodwaste_1314_foodlevel as
    SELECT
           SEQN,food_group,
			sum(fcid_gram) as cons_foodsum,	
            sum(waste_amount) as waste_foodsum, 
			sum (ed_amount) as ed_foodsum, 
          sum(ined_amount) as ined_foodsum,
		  sum(pur_amount) as pur_foodsum
    FROM foodwaste_dga

    GROUP BY SEQN,food_group;
	

quit;



/*proc print data=foodwaste_1314_foodlevel (obs=20);run;*/

/*8.	Can transpose to wide data, so data is at the individual level, with columns showing grams of food waste per food group*/

proc transpose data=foodwaste_1314_foodlevel out=foodwasteamt_1314_ind (drop=_NAME_) prefix=wasteamt_ ;
by seqn;
id food_group;
var waste_foodsum; 
run;
proc transpose data=foodwaste_1314_foodlevel out=foodedamt_1314_ind (drop=_NAME_) prefix=edamt_ ;
by seqn;
id food_group;
var ed_foodsum; 
run;
 proc transpose data=foodwaste_1314_foodlevel out=foodinedamt_1314_ind (drop=_NAME_) prefix=inedamt_ ;
by seqn;
id food_group;
var ined_foodsum;
run;
proc transpose data=foodwaste_1314_foodlevel out=foodpuramt_1314_ind (drop=_NAME_) prefix=puramt_ ;
by seqn;
id food_group;
var pur_foodsum;
run;
proc transpose data=foodwaste_1314_foodlevel out=foodconsamt_1314_ind (drop=_NAME_) prefix=consamt_ ;
by seqn;
id food_group;
var cons_foodsum;
run;



/*change missing to zero*/

data foodwasteamt_1314_ind ;
set foodwasteamt_1314_ind;
array fgroups {20} wasteamt_added_sugar wasteamt_dairy wasteamt_fruit wasteamt_gr_refined wasteamt_oil 
wasteamt_pf_egg wasteamt_pf_ns wasteamt_pf_rm wasteamt_pf_soy wasteamt_sat_fat wasteamt_veg_oth wasteamt_veg_ro 
wasteamt_veg_sta wasteamt_gr_whole wasteamt_other wasteamt_pf_seafood wasteamt_pf_poultry wasteamt_veg_dg wasteamt_veg_leg wasteamt_babyfood;
do i=1 to dim(fgroups);
	if fgroups(i)=. then fgroups(i)=0;
	end;
	drop i;
run;

data foodedamt_1314_ind ;
set foodedamt_1314_ind;
array fgroups {20} edamt_added_sugar edamt_dairy edamt_fruit edamt_gr_refined edamt_oil edamt_pf_egg edamt_pf_ns edamt_pf_rm edamt_pf_soy 
edamt_sat_fat edamt_veg_oth edamt_veg_ro edamt_veg_sta edamt_gr_whole edamt_other edamt_pf_seafood edamt_pf_poultry edamt_veg_dg 
edamt_veg_leg edamt_babyfood;
do i=1 to dim(fgroups);
	if fgroups(i)=. then fgroups(i)=0;
	end;
	drop i;
run;

data foodinedamt_1314_ind ;
set foodinedamt_1314_ind;
array fgroups {20}

inedamt_added_sugar inedamt_dairy inedamt_fruit inedamt_gr_refined inedamt_oil inedamt_pf_egg inedamt_pf_ns inedamt_pf_rm inedamt_pf_soy 
inedamt_sat_fat inedamt_veg_oth inedamt_veg_ro inedamt_veg_sta inedamt_gr_whole inedamt_other inedamt_pf_seafood inedamt_pf_poultry inedamt_veg_dg inedamt_veg_leg 
inedamt_babyfood;
do i=1 to dim(fgroups);
	if fgroups(i)=. then fgroups(i)=0;
	end;
	drop i;
run;

data foodconsamt_1314_ind ;
set foodconsamt_1314_ind;
array fgroups {20}
consamt_added_sugar consamt_dairy consamt_fruit consamt_gr_refined consamt_oil consamt_pf_egg consamt_pf_ns consamt_pf_rm consamt_pf_soy consamt_sat_fat 
consamt_veg_oth consamt_veg_ro consamt_veg_sta consamt_gr_whole consamt_other consamt_pf_seafood consamt_pf_poultry consamt_veg_dg consamt_veg_leg consamt_babyfood;
do i=1 to dim(fgroups);
	if fgroups(i)=. then fgroups(i)=0;
	end;
	drop i;
run;

data foodpuramt_1314_ind ;
set foodpuramt_1314_ind;
array fgroups {20}
puramt_added_sugar puramt_dairy puramt_fruit puramt_gr_refined puramt_oil puramt_pf_egg puramt_pf_ns puramt_pf_rm puramt_pf_soy puramt_sat_fat 
puramt_veg_oth puramt_veg_ro puramt_veg_sta puramt_gr_whole puramt_other puramt_pf_seafood puramt_pf_poultry puramt_veg_dg puramt_veg_leg puramt_babyfood;
	do i=1 to dim(fgroups);
	if fgroups(i)=. then fgroups(i)=0;
	end;
	drop i;
run;

/*merge amount and proportion data*/
proc sort data=foodwasteamt_1314_ind; by seqn;run;
proc sort data=foodinedamt_1314_ind; by seqn;run;
proc sort data=foodconsamt_1314_ind; by seqn;run;
proc sort data=foodpuramt_1314_ind; by seqn;run;
proc sort data=foodedamt_1314_ind; by seqn;run;

data foodwaste_1314_ind;
merge foodwasteamt_1314_ind (in=w) foodinedamt_1314_ind(in=ined) foodconsamt_1314_ind (in=cons) foodpuramt_1314_ind (in=pur) foodedamt_1314_ind (in=ed);
if w and ined and pur and cons and ed;
run;




/*8.	Sum by food group */
/*read in demo data and merge in survey wegihts data*/
data demo1314 (keep=year seqn wtint2yr wtmec2yr sdmvstra sdmvpsu ridageyr ridreth1 dmdeduc2 indfmpir age adult race edu pedu pir riagendr DMDHREDU);
set lasting.demo_h;
/*age*/
if ridageyr in (0:1) then age=0;
if ridageyr in (2:5) then age=1;
if ridageyr in (6:11) then age=2;
	if ridageyr in (12:19) then age=3;
      if ridageyr in (20:44) then age=4;
      else if ridageyr in (45:54) then age=5;
      else if ridageyr in (55:64) then age=6;
      else if ridageyr>=65 then age=7; 
/*binary adult variable */
if age<4 then adult =0;
if age >=4 then adult =1;
/* race group */
      if ridreth1=3 then race=1; /*non-Hispanic white*/
      if ridreth1=4 then race=2; /*non-Hispanic black*/
      if ridreth1 in (1,2) then race=3; /*Hispanic*/
      if ridreth1 in (5) then race=4; /*Other*/
      /*parental education group*/
 
      if DMDHREDU in (1,2) then pedu=1;  /*Lower than secondary school*/
      if DMDHREDU in (3) then pedu=2; /*High school or GED*/
      if DMDHREDU in (4,5) then pedu=3; /*Some college or above*/
     /* education group*/
 
      if dmdeduc2 in (1,2) then edu=1;  /*Lower than secondary school*/
      if dmdeduc2 in (3) then edu=2; /*High school or GED*/
      if dmdeduc2 in (4,5) then edu=3; /*Some college or above*/

/*Income group: accriding to income to poverty ratio */
      if  indfmpir < 1.3 and indfmpir ne . then pir = 1;
      if indfmpir >= 1.3 then pir = 2;
      if indfmpir >= 3 then pir = 3;

run;

/*create subgroups 1=M*/
data demo1314;
set demo1314;
if riagendr=2 AND age=4 AND race=1  then subgroup=1; /*Female	Age_2044	Non-hispanic White*/
else if riagendr=2 AND age=4 AND race=2  then subgroup=2;/*Female	Age_2044	Non-hispanic Black*/
else if riagendr=2 AND age=4 AND race=3  then subgroup=3;/*Female	Age_2044	Hispanic*/
else if riagendr=2 AND age=4 AND race=4  then subgroup=4;/*Female	Age_2044	Other*/
else if riagendr=1 AND age=4 AND race=1  then subgroup=5; /*male	Age_2044	Non-hispanic White*/
else if riagendr=1 AND age=4 AND race=2  then subgroup=6;/*male	Age_2044	Non-hispanic Black*/
else if riagendr=1 AND age=4 AND race=3  then subgroup=7;/*male	Age_2044	Hispanic*/
else if riagendr=1 AND age=4 AND race=4  then subgroup=8;/*male	Age_2044	Other*/

else if riagendr=2 AND age=5 AND race=1  then subgroup=9; /*Female	Age_4554	Non-hispanic White*/
else if riagendr=2 AND age=5 AND race=2  then subgroup=10;/*Female	Age_4554	Non-hispanic Black*/
else if riagendr=2 AND age=5 AND race=3  then subgroup=11;/*Female	Age_4554	Hispanic*/
else if riagendr=2 AND age=5 AND race=4  then subgroup=12;/*Female	Age_4554	Other*/
else if riagendr=1 AND age=5 AND race=1  then subgroup=13; /*male	Age_4554	Non-hispanic White*/
else if riagendr=1 AND age=5 AND race=2  then subgroup=14;/*male	Age_4554	Non-hispanic Black*/
else if riagendr=1 AND age=5 AND race=3  then subgroup=15;/*male	Age_4554	Hispanic*/
else if riagendr=1 AND age=5 AND race=4  then subgroup=16;/*male	Age_4554	Other*/

else if riagendr=2 AND age=6 AND race=1  then subgroup=17; /*Female	Age_5564	Non-hispanic White*/
else if riagendr=2 AND age=6 AND race=2  then subgroup=18;/*Female	Age_5564	Non-hispanic Black*/
else if riagendr=2 AND age=6 AND race=3  then subgroup=19;/*Female	Age_5564	Hispanic*/
else if riagendr=2 AND age=6 AND race=4  then subgroup=20;/*Female	Age_5564	Other*/
else if riagendr=1 AND age=6 AND race=1  then subgroup=21; /*male	Age_5564	Non-hispanic White*/
else if riagendr=1 AND age=6 AND race=2  then subgroup=22;/*male	Age_5564	Non-hispanic Black*/
else if riagendr=1 AND age=6 AND race=3  then subgroup=23;/*male	Age_5564	Hispanic*/
else if riagendr=1 AND age=6 AND race=4  then subgroup=24;/*male	Age_5564	Other*/

else if riagendr=2 AND age=7 AND race=1  then subgroup=25; /*Female	Age_over65	Non-hispanic White*/
else if riagendr=2 AND age=7 AND race=2  then subgroup=26;/*Female	Age_over65	Non-hispanic Black*/
else if riagendr=2 AND age=7 AND race=3  then subgroup=27;/*Female	Age_over65	Hispanic*/
else if riagendr=2 AND age=7 AND race=4  then subgroup=28;/*Female	Age_over65	Other*/
else if riagendr=1 AND age=7 AND race=1  then subgroup=29; /*male	Age_over65	Non-hispanic White*/
else if riagendr=1 AND age=7 AND race=2  then subgroup=30;/*male	Age_over65	Non-hispanic Black*/
else if riagendr=1 AND age=7 AND race=3  then subgroup=31;/*male	Age_over65	Hispanic*/
else if riagendr=1 AND age=7 AND race=4  then subgroup=32;/*male	Age_over65	Other*/

run;
 

proc sort data=demo1314;
by seqn;run;
proc sort data =foodwaste_1314_ind;
by seqn;run;
data nhanes_1314_weight (keep=seqn WTDRD1);
set  nhanes1314d1;
run;
proc sort data =nhanes_1314_weight nodupkey;
by seqn WTDRD1;run;

data foodwaste_1314_demo;
merge demo1314 (in=d) foodwaste_1314_ind(in=f) nhanes_1314_weight (in=w);
by seqn;
if f;

run;
/*subset to adults aged 20+ only;*/
data foodwaste_1314_demo;
set foodwaste_1314_demo;
where age>3;
run;


/*mean for all population */
proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1 ; 
var  wasteamt_added_sugar wasteamt_dairy wasteamt_fruit wasteamt_gr_refined wasteamt_oil wasteamt_pf_egg wasteamt_pf_ns wasteamt_pf_rm wasteamt_pf_soy 
wasteamt_sat_fat wasteamt_veg_oth wasteamt_veg_ro wasteamt_veg_sta wasteamt_gr_whole wasteamt_other wasteamt_pf_seafood wasteamt_pf_poultry wasteamt_veg_dg 
wasteamt_veg_leg wasteamt_babyfood; 
ods output statistics= foodwasteamtmean;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1 ; 
var  edamt_added_sugar edamt_dairy edamt_fruit edamt_gr_refined edamt_oil edamt_pf_egg edamt_pf_ns edamt_pf_rm edamt_pf_soy 
edamt_sat_fat edamt_veg_oth edamt_veg_ro edamt_veg_sta edamt_gr_whole edamt_other edamt_pf_seafood edamt_pf_poultry edamt_veg_dg 
edamt_veg_leg edamt_babyfood; 
ods output statistics= foodedamtmean;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1 ; 
var inedamt_added_sugar inedamt_dairy inedamt_fruit inedamt_gr_refined inedamt_oil inedamt_pf_egg inedamt_pf_ns inedamt_pf_rm inedamt_pf_soy 
inedamt_sat_fat inedamt_veg_oth inedamt_veg_ro inedamt_veg_sta inedamt_gr_whole inedamt_other inedamt_pf_seafood inedamt_pf_poultry inedamt_veg_dg inedamt_veg_leg 
inedamt_babyfood;
ods output statistics=foodinedamtmean;run;


proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1 ; 
var 

consamt_added_sugar consamt_dairy consamt_fruit consamt_gr_refined consamt_oil consamt_pf_egg consamt_pf_ns consamt_pf_rm consamt_pf_soy consamt_sat_fat 
consamt_veg_oth consamt_veg_ro consamt_veg_sta consamt_gr_whole consamt_other consamt_pf_seafood consamt_pf_poultry consamt_veg_dg consamt_veg_leg consamt_babyfood;
ods output statistics=foodconsamtmean; 
run;
proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1 ; 
var 
puramt_added_sugar puramt_dairy puramt_fruit puramt_gr_refined puramt_oil puramt_pf_egg puramt_pf_ns puramt_pf_rm puramt_pf_soy puramt_sat_fat 
puramt_veg_oth puramt_veg_ro puramt_veg_sta puramt_gr_whole puramt_other puramt_pf_seafood puramt_pf_poultry puramt_veg_dg puramt_veg_leg puramt_babyfood;
ods output statistics=foodpuramtmean; 
run;


data foodpuramtmean;
set foodpuramtmean;
Var=substr(varname,8);
rename mean=pur_mean;
rename stderr=pur_se;
drop varname;
run;

data foodinedamtmean;
set foodinedamtmean;
Var=substr(varname,9);
rename mean=ined_mean;
rename stderr=ined_se;
drop varname;
run;

data foodedamtmean;
set foodedamtmean;
Var=substr(varname,7);
rename mean=ed_mean;
rename stderr=ed_se;
drop varname;
run;

data foodconsamtmean;
set foodconsamtmean;
Var=substr(varname,9);
rename mean=cons_mean;
rename stderr=cons_se;
drop varname;
run;

data foodwasteamtmean;
set foodwasteamtmean;
Var=substr(varname,10);
rename mean=waste_mean;
rename stderr=waste_se;
drop varname;
run;



proc sort data=foodwasteamtmean;
by Var;run;
proc sort data =foodconsamtmean;
by Var;run;
proc sort data=foodpuramtmean ;
by Var;run;
proc sort data =foodinedamtmean ;
by Var;run;
proc sort data = foodedamtmean ;
by Var;run;

data foodwaste_demo_all;
merge foodwasteamtmean (in=w) foodconsamtmean (in=c) foodpuramtmean (in=p) foodinedamtmean (in=i) foodedamtmean(in=e) ;
by Var;
waste_portion=waste_mean/ed_mean*100;
ined_portion=ined_mean/pur_mean*100;
run;





ods excel file="C:\Users\bbell06\Box\lasting_aim_3\planning\Methods of estimating food waste and inedible portion\results\foodwastemean_%sysfunc(today(), mmddyyd10.).xlsx" 
options(sheet_name="foodwaste_surveymean");
proc report data=foodwasteamtmean;
columns _all_;
run;

ods excel options (sheet_name="inedible_surveymean");
proc report data=foodinedamtmean;
columns _all_;
run;

ods excel options (sheet_name="consumed_surveymean");
proc report data=foodconsamtmean;
columns _all_;
run;

ods excel options (sheet_name="purchased_surveymean");
proc report data=foodpuramtmean;
columns _all_;
run;

ods excel options (sheet_name="edible_surveymean");
proc report data=foodedamtmean;
columns _all_;
run;
ods excel close;


/*macro to calculate subpopulation mean*/
%macro foodwastesubpopmean(domain=);
proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var wasteamt_added_sugar wasteamt_dairy wasteamt_fruit wasteamt_gr_refined wasteamt_oil wasteamt_pf_egg wasteamt_pf_ns wasteamt_pf_rm wasteamt_pf_soy 
wasteamt_sat_fat wasteamt_veg_oth wasteamt_veg_ro wasteamt_veg_sta wasteamt_gr_whole wasteamt_other wasteamt_pf_seafood wasteamt_pf_poultry wasteamt_veg_dg 
wasteamt_veg_leg wasteamt_babyfood ;  
domain &domain;
format &domain &domain.f.;
ods output domain= wastemean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var inedamt_added_sugar inedamt_dairy inedamt_fruit inedamt_gr_refined inedamt_oil inedamt_pf_egg inedamt_pf_ns inedamt_pf_rm inedamt_pf_soy 
inedamt_sat_fat inedamt_veg_oth inedamt_veg_ro inedamt_veg_sta inedamt_gr_whole inedamt_other inedamt_pf_seafood inedamt_pf_poultry inedamt_veg_dg inedamt_veg_leg 
inedamt_babyfood;  
domain &domain;
format &domain &domain.f.;
ods output domain= inedmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var consamt_added_sugar consamt_dairy consamt_fruit consamt_gr_refined consamt_oil consamt_pf_egg consamt_pf_ns consamt_pf_rm consamt_pf_soy consamt_sat_fat 
consamt_veg_oth consamt_veg_ro consamt_veg_sta consamt_gr_whole consamt_other consamt_pf_seafood consamt_pf_poultry consamt_veg_dg consamt_veg_leg consamt_babyfood;  
domain &domain;
format &domain &domain.f.;
ods output domain= consmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var puramt_added_sugar puramt_dairy puramt_fruit puramt_gr_refined puramt_oil puramt_pf_egg puramt_pf_ns puramt_pf_rm puramt_pf_soy puramt_sat_fat 
puramt_veg_oth puramt_veg_ro puramt_veg_sta puramt_gr_whole puramt_other puramt_pf_seafood puramt_pf_poultry puramt_veg_dg puramt_veg_leg puramt_babyfood ;  
domain &domain;
format &domain &domain.f.;
ods output domain= purmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var edamt_added_sugar edamt_dairy edamt_fruit edamt_gr_refined edamt_oil edamt_pf_egg edamt_pf_ns edamt_pf_rm edamt_pf_soy 
edamt_sat_fat edamt_veg_oth edamt_veg_ro edamt_veg_sta edamt_gr_whole edamt_other edamt_pf_seafood edamt_pf_poultry edamt_veg_dg 
edamt_veg_leg edamt_babyfood ;  
domain &domain;
format &domain &domain.f.;
ods output domain= edmean_&domain;
run;




/*rename columns and variable */

data purmean_&domain;
set purmean_&domain;
Var=substr(varname,8);
rename mean=pur_mean;
rename stderr=pur_se;
drop varname;
run;

data inedmean_&domain;
set inedmean_&domain;
Var=substr(varname,9);
rename mean=ined_mean;
rename stderr=ined_se;
drop varname;
run;

data edmean_&domain;
set edmean_&domain;
Var=substr(varname,7);
rename mean=ed_mean;
rename stderr=ed_se;
drop varname;
run;

data consmean_&domain;
set consmean_&domain;
Var=substr(varname,9);
rename mean=cons_mean;
rename stderr=cons_se;
drop varname;
run;

data wastemean_&domain;
set wastemean_&domain;
Var=substr(varname,10);
rename mean=waste_mean;
rename stderr=waste_se;
drop varname;
run;

/*sort and merge*/;

proc sort data=wastemean_&domain ;
by &domain var;
run; 

proc sort data=consmean_&domain ;
by &domain var;
run; 
proc sort data=inedmean_&domain ;
by &domain var;
run; 
proc sort data=purmean_&domain ;
by &domain var;
run;
proc sort data=edmean_&domain ;
by &domain var;
run; 

data foodwaste_&domain;
merge wastemean_&domain (in=w) consmean_&domain (in=c) purmean_&domain (in=p) inedmean_&domain (in=i) edmean_&domain(in=e) ;
by &domain var;
format &domain &domain.f.;
waste_portion=waste_mean/ed_mean*100;
ined_portion=ined_mean/pur_mean*100;
run;

%mend;
%foodwastesubpopmean(domain=race);
%foodwastesubpopmean(domain=edu);
%foodwastesubpopmean(domain=pir);
%foodwastesubpopmean(domain=riagendr);
%foodwastesubpopmean(domain=age);

/*to calcualte mean by 32 demographic subgroups */
%macro foodwastesubpopmean2(domain=);
proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var wasteamt_added_sugar wasteamt_dairy wasteamt_fruit wasteamt_gr_refined wasteamt_oil wasteamt_pf_egg wasteamt_pf_ns wasteamt_pf_rm wasteamt_pf_soy 
wasteamt_sat_fat wasteamt_veg_oth wasteamt_veg_ro wasteamt_veg_sta wasteamt_gr_whole wasteamt_other wasteamt_pf_seafood wasteamt_pf_poultry wasteamt_veg_dg 
wasteamt_veg_leg wasteamt_babyfood ;  
domain &domain;
format &domain ;
ods output domain= wastemean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var inedamt_added_sugar inedamt_dairy inedamt_fruit inedamt_gr_refined inedamt_oil inedamt_pf_egg inedamt_pf_ns inedamt_pf_rm inedamt_pf_soy 
inedamt_sat_fat inedamt_veg_oth inedamt_veg_ro inedamt_veg_sta inedamt_gr_whole inedamt_other inedamt_pf_seafood inedamt_pf_poultry inedamt_veg_dg inedamt_veg_leg 
inedamt_babyfood;  
domain &domain;
format &domain;
ods output domain= inedmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var consamt_added_sugar consamt_dairy consamt_fruit consamt_gr_refined consamt_oil consamt_pf_egg consamt_pf_ns consamt_pf_rm consamt_pf_soy consamt_sat_fat 
consamt_veg_oth consamt_veg_ro consamt_veg_sta consamt_gr_whole consamt_other consamt_pf_seafood consamt_pf_poultry consamt_veg_dg consamt_veg_leg consamt_babyfood;  
domain &domain;
format &domain ;
ods output domain= consmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var puramt_added_sugar puramt_dairy puramt_fruit puramt_gr_refined puramt_oil puramt_pf_egg puramt_pf_ns puramt_pf_rm puramt_pf_soy puramt_sat_fat 
puramt_veg_oth puramt_veg_ro puramt_veg_sta puramt_gr_whole puramt_other puramt_pf_seafood puramt_pf_poultry puramt_veg_dg puramt_veg_leg puramt_babyfood ;  
domain &domain;
format &domain;
ods output domain= purmean_&domain;
run;

proc surveymeans data=foodwaste_1314_demo mean;
strata sdmvstra;
cluster sdmvpsu;
weight WTDRD1  ; /*for combining cycles weight will be WTDRD1/number of cycles **/
var edamt_added_sugar edamt_dairy edamt_fruit edamt_gr_refined edamt_oil edamt_pf_egg edamt_pf_ns edamt_pf_rm edamt_pf_soy 
edamt_sat_fat edamt_veg_oth edamt_veg_ro edamt_veg_sta edamt_gr_whole edamt_other edamt_pf_seafood edamt_pf_poultry edamt_veg_dg 
edamt_veg_leg edamt_babyfood ;  
domain &domain;
format &domain ;
ods output domain= edmean_&domain;
run;




/*rename columns and variable */

data purmean_&domain;
set purmean_&domain;
Var=substr(varname,8);
rename mean=pur_mean;
rename stderr=pur_se;
drop varname;
run;

data inedmean_&domain;
set inedmean_&domain;
Var=substr(varname,9);
rename mean=ined_mean;
rename stderr=ined_se;
drop varname;
run;

data edmean_&domain;
set edmean_&domain;
Var=substr(varname,7);
rename mean=ed_mean;
rename stderr=ed_se;
drop varname;
run;

data consmean_&domain;
set consmean_&domain;
Var=substr(varname,9);
rename mean=cons_mean;
rename stderr=cons_se;
drop varname;
run;

data wastemean_&domain;
set wastemean_&domain;
Var=substr(varname,10);
rename mean=waste_mean;
rename stderr=waste_se;
drop varname;
run;

/*sort and merge*/;

proc sort data=wastemean_&domain ;
by &domain var;
run; 

proc sort data=consmean_&domain ;
by &domain var;
run; 
proc sort data=inedmean_&domain ;
by &domain var;
run; 
proc sort data=purmean_&domain ;
by &domain var;
run;
proc sort data=edmean_&domain ;
by &domain var;
run; 

data foodwaste_&domain;
merge wastemean_&domain (in=w) consmean_&domain (in=c) purmean_&domain (in=p) inedmean_&domain (in=i) edmean_&domain(in=e) ;
by &domain var;
format &domain ;
waste_portion=waste_mean/ed_mean*100;
ined_portion=ined_mean/pur_mean*100;
run;

%mend;
%foodwastesubpopmean2(domain=subgroup);
proc sort data=foodwaste_subgroup;
by var;run; 
data foodwaste_subgroup;
set foodwaste_subgroup;
rename var=Foodgroup subgroup=subgroup_id;
run; 

ods excel file="C:\Users\bbell06\Box\lasting_aim_3\planning\Methods of estimating food waste and inedible portion\results\foodwastemean_32subgroup_%sysfunc(today(), mmddyyd10.).xlsx" 
options (sheet_name="32subgroups");
options nolabel;
proc print data=foodwaste_subgroup;
var Foodgroup subgroup_id waste_mean waste_se cons_mean cons_se pur_mean pur_se ined_mean ined_se ed_mean ed_se waste_portion ined_portion ;
run;
ods excel close; 


ods excel file="C:\Users\bbell06\Box\lasting_aim_3\planning\Methods of estimating food waste and inedible portion\results\foodwastemean_demo_%sysfunc(today(), mmddyyd10.).xlsx" 
options (sheet_name="all");
proc report data=foodwaste_demo_all;run;

ods excel options (sheet_name="race");
proc report data=foodwaste_race;
columns _all_;
run;

ods excel options (sheet_name="edu");
proc report data=foodwaste_edu;
columns _all_;
run;

ods excel options (sheet_name="income");
proc report data=foodwaste_pir;
columns _all_;
run;

ods excel options (sheet_name="gender");
proc report data=foodwaste_riagendr;
columns _all_;
run;

ods excel options (sheet_name="age");
proc report data=foodwaste_age;
columns _all_;
run;


ods excel close;
