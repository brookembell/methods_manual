libname obesity "C:\Users\zgu02\Box\lasting_aim_3\model development\data_new\in\Proportion of overweight&obesity\data"; 
/*1718*/
data BMI1718; set obesity.overweight1718;
keep SEQN BMDSTATS BMXBMI;
run;

data demo1718;set obesity.demo1718;
keep SEQN SDDSRVYR RIAGENDR RIDAGEYR RIDRETH1 sdmvpsu sdmvstra WTMEC2YR;
run;

proc sort data=demo1718;by seqn;run;
proc sort data=BMI1718;by seqn;run;

data overweight1718;merge demo1718 BMI1718;by seqn;run;

data overweight1718; set overweight1718;where BMDSTATS<>. and BMDSTATS<>4 and RIDAGEYR>24;
overweight=.;
if BMXBMI >= 25 then overweight=1;else if 0<BMXBMI<25 then overweight=0;
run;

/*create age groups*/
data overweight1718;set overweight1718;
age=. ;
if 19<RIDAGEYR<=34 then age=1 ;
if 35<=RIDAGEYR<=44 then age=2 ;
if 45<=RIDAGEYR<=54 then age=3 ;
if 55<=RIDAGEYR<=64 then age=4 ;
if 65<=RIDAGEYR<=74 then age=5 ;
if 75<=RIDAGEYR then age=6 ;
run;
data overweight1718;set overweight1718;
if age=1 then agelabel='20-34y';
if age=2 then agelabel='35-44y';
if age=3 then agelabel='45-54y';
if age=4 then agelabel='55-64y';
if age=5 then agelabel='65-74y';
if age=6 then agelabel='75y+';
run;

/*gender label*/
data overweight1718;set overweight1718;
if RIAGENDR=1 then gender=2;
if RIAGENDR=2 then gender=1;
if  gender=1 then gender_='F';
if  gender=2 then gender_='M';
run;

/*create ethic groups*/
data overweight1718;set overweight1718;
if RIDRETH1=3 then race=1;
if RIDRETH1=4 then race=2;
if RIDRETH1=1 or RIDRETH1=2 then race=3;
if RIDRETH1=5 then race=4;
run;
data overweight1718;set overweight1718;
if race=1 then race_='NHW';
if race=2 then race_='NHB';
if race=3 then race_='HIS';
if race=4 then race_='OTH';
run;

/*combine subgroups*/
data overweight1718group;set overweight1718;
if age=1 and gender=1 and race=1 then group=1;
if age=1 and gender=1 and race=2 then group=2;
if age=1 and gender=1 and race=3 then group=3;
if age=1 and gender=1 and race=4 then group=4;
if age=1 and gender=2 and race=1 then group=5;
if age=1 and gender=2 and race=2 then group=6;
if age=1 and gender=2 and race=3 then group=7;
if age=1 and gender=2 and race=4 then group=8;
if age=2 and gender=1 and race=1 then group=9;
if age=2 and gender=1 and race=2 then group=10;
if age=2 and gender=1 and race=3 then group=11;
if age=2 and gender=1 and race=4 then group=12;
if age=2 and gender=2 and race=1 then group=13;
if age=2 and gender=2 and race=2 then group=14;
if age=2 and gender=2 and race=3 then group=15;
if age=2 and gender=2 and race=4 then group=16;
if age=3 and gender=1 and race=1 then group=17;
if age=3 and gender=1 and race=2 then group=18;
if age=3 and gender=1 and race=3 then group=19;
if age=3 and gender=1 and race=4 then group=20;
if age=3 and gender=2 and race=1 then group=21;
if age=3 and gender=2 and race=2 then group=22;
if age=3 and gender=2 and race=3 then group=23;
if age=3 and gender=2 and race=4 then group=24;
if age=4 and gender=1 and race=1 then group=25;
if age=4 and gender=1 and race=2 then group=26;
if age=4 and gender=1 and race=3 then group=27;
if age=4 and gender=1 and race=4 then group=28;
if age=4 and gender=2 and race=1 then group=29;
if age=4 and gender=2 and race=2 then group=30;
if age=4 and gender=2 and race=3 then group=31;
if age=4 and gender=2 and race=4 then group=32;
if age=5 and gender=1 and race=1 then group=33;
if age=5 and gender=1 and race=2 then group=34;
if age=5 and gender=1 and race=3 then group=35;
if age=5 and gender=1 and race=4 then group=36;
if age=5 and gender=2 and race=1 then group=37;
if age=5 and gender=2 and race=2 then group=38;
if age=5 and gender=2 and race=3 then group=39;
if age=5 and gender=2 and race=4 then group=40;
if age=6 and gender=1 and race=1 then group=41;
if age=6 and gender=1 and race=2 then group=42;
if age=6 and gender=1 and race=3 then group=43;
if age=6 and gender=1 and race=4 then group=44;
if age=6 and gender=2 and race=1 then group=45;
if age=6 and gender=2 and race=2 then group=46;
if age=6 and gender=2 and race=3 then group=47;
if age=6 and gender=2 and race=4 then group=48;
run;

data overweight1718group;set overweight1718group;
length grp $25;
grp=trim(agelabel)||" "||trim(gender_) ||" "||trim(race_);
run;

/*calculate overweight ratio*/
proc sort data=overweight1718group;
by group;run;

/*0929update*/
ods output OneWay=B;
proc surveyfreq data=overweight1718group;
tables overweight;
strata sdmvstra;
cluster sdmvpsu;
weight WTMEC2YR ; 
by group;
run;

data overweightrate1718;set B;
where overweight=1;drop Table _SkipLine;
run;
/**/


/*1516*/
data BMI1516; set obesity.overweight1516;
keep SEQN BMDSTATS BMXBMI;
run;

data demo1516;set obesity.demo1516;
keep SEQN SDDSRVYR RIAGENDR RIDAGEYR RIDRETH1 sdmvpsu sdmvstra WTMEC2YR;
run;

proc sort data=demo1516;by seqn;run;
proc sort data=BMI1516;by seqn;run;

data overweight1516;merge demo1516 BMI1516;by seqn;run;

data overweight1516; set overweight1516;where BMDSTATS<>. and BMDSTATS<>4 and RIDAGEYR>24;
overweight=.;
if BMXBMI >= 25 then overweight=1;else if 0<BMXBMI<25 then overweight=0;
run;

/*create age groups*/
data overweight1516;set overweight1516;
age=. ;
if 19<RIDAGEYR<=34 then age=1 ;
if 35<=RIDAGEYR<=44 then age=2 ;
if 45<=RIDAGEYR<=54 then age=3 ;
if 55<=RIDAGEYR<=64 then age=4 ;
if 65<=RIDAGEYR<=74 then age=5 ;
if 75<=RIDAGEYR then age=6 ;
run;
data overweight1516;set overweight1516;
if age=1 then agelabel='20-34y';
if age=2 then agelabel='35-44y';
if age=3 then agelabel='45-54y';
if age=4 then agelabel='55-64y';
if age=5 then agelabel='65-74y';
if age=6 then agelabel='75y+';
run;

/*gender label*/
data overweight1516;set overweight1516;
if RIAGENDR=1 then gender=2;
if RIAGENDR=2 then gender=1;
if  gender=1 then gender_='F';
if  gender=2 then gender_='M';
run;

/*create ethic groups*/
data overweight1516;set overweight1516;
if RIDRETH1=3 then race=1;
if RIDRETH1=4 then race=2;
if RIDRETH1=1 or RIDRETH1=2 then race=3;
if RIDRETH1=5 then race=4;
run;
data overweight1516;set overweight1516;
if race=1 then race_='NHW';
if race=2 then race_='NHB';
if race=3 then race_='HIS';
if race=4 then race_='OTH';
run;

/*combine subgroups*/
data overweight1516group;set overweight1516;
if age=1 and gender=1 and race=1 then group=1;
if age=1 and gender=1 and race=2 then group=2;
if age=1 and gender=1 and race=3 then group=3;
if age=1 and gender=1 and race=4 then group=4;
if age=1 and gender=2 and race=1 then group=5;
if age=1 and gender=2 and race=2 then group=6;
if age=1 and gender=2 and race=3 then group=7;
if age=1 and gender=2 and race=4 then group=8;
if age=2 and gender=1 and race=1 then group=9;
if age=2 and gender=1 and race=2 then group=10;
if age=2 and gender=1 and race=3 then group=11;
if age=2 and gender=1 and race=4 then group=12;
if age=2 and gender=2 and race=1 then group=13;
if age=2 and gender=2 and race=2 then group=14;
if age=2 and gender=2 and race=3 then group=15;
if age=2 and gender=2 and race=4 then group=16;
if age=3 and gender=1 and race=1 then group=17;
if age=3 and gender=1 and race=2 then group=18;
if age=3 and gender=1 and race=3 then group=19;
if age=3 and gender=1 and race=4 then group=20;
if age=3 and gender=2 and race=1 then group=21;
if age=3 and gender=2 and race=2 then group=22;
if age=3 and gender=2 and race=3 then group=23;
if age=3 and gender=2 and race=4 then group=24;
if age=4 and gender=1 and race=1 then group=25;
if age=4 and gender=1 and race=2 then group=26;
if age=4 and gender=1 and race=3 then group=27;
if age=4 and gender=1 and race=4 then group=28;
if age=4 and gender=2 and race=1 then group=29;
if age=4 and gender=2 and race=2 then group=30;
if age=4 and gender=2 and race=3 then group=31;
if age=4 and gender=2 and race=4 then group=32;
if age=5 and gender=1 and race=1 then group=33;
if age=5 and gender=1 and race=2 then group=34;
if age=5 and gender=1 and race=3 then group=35;
if age=5 and gender=1 and race=4 then group=36;
if age=5 and gender=2 and race=1 then group=37;
if age=5 and gender=2 and race=2 then group=38;
if age=5 and gender=2 and race=3 then group=39;
if age=5 and gender=2 and race=4 then group=40;
if age=6 and gender=1 and race=1 then group=41;
if age=6 and gender=1 and race=2 then group=42;
if age=6 and gender=1 and race=3 then group=43;
if age=6 and gender=1 and race=4 then group=44;
if age=6 and gender=2 and race=1 then group=45;
if age=6 and gender=2 and race=2 then group=46;
if age=6 and gender=2 and race=3 then group=47;
if age=6 and gender=2 and race=4 then group=48;
run;

data overweight1516group;set overweight1516group;
length grp $25;
grp=trim(agelabel)||" "||trim(gender_) ||" "||trim(race_);
run;

/*calculate overweight ratio*/
proc sort data=overweight1516group;
by group;run;

ods output OneWay=C;
proc surveyfreq data=overweight1516group; 
tables overweight;
strata sdmvstra;
cluster sdmvpsu;
weight WTMEC2YR ; 
by group;
run;

data overweightrate1516;set C;
where overweight=1;drop Table _SkipLine;
run;

/*combine 15-18*/
data overweight1518;set overweight1516group overweight1718group;WTMEC4YR=WTMEC2YR/2;
run;

proc sort data=overweight1518;
by group;run;

ods output OneWay=D;
proc surveyfreq data=overweight1518;
tables overweight;
strata sdmvstra;
cluster sdmvpsu;
weight WTMEC4YR ; 
by group;
run;

data overweightrate1518;set D;
where overweight=1;drop Table _SkipLine;
run;


