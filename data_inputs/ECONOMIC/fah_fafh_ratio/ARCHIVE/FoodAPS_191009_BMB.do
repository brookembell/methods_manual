********************************************************************************
*FAFH: ESTIMATE COST PER GRAM OF EACH FOOD
********************************************************************************

*Original author is Zach Conrad
*Edits by Brooke Bell
*Last updated on 4/13/23

clear

*IMPORT DATASET

*use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fafhitem_puf"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_fafhitem_puf"


*Format variables
keep hhnum eventid itemnum itemdesc gramstotal totitemcost imptotcost

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

replace totitemcost=imptotcost if totitemcost==.
drop imptotcost

rename itemdesc desc
rename gramstotal grams
rename totitemcost cost

format desc %60s

*Estimate cost per gram of each food
gen cost_g=cost/grams

	*replace cost_g=. if cost_g==0
	*replace cost=. if cost==0

*save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh_itemcost", replace
save "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fafh_itemcost", replace


********************************************************************************
*FAFH: MERGE ITEM COST WITH FOOD CATEGORIES
********************************************************************************
clear
* use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fafhnutrient_puf"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_fafhnutrient_puf"

* Format variables
keep hhnum eventid itemnum usdafoodcat1 usdafoodcat2 usdafoodcat4 foodcode codenot1112 usdadescmain pf_soy
rename foodcode foodcode1

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

* Categorize FNDDS-coded foods

* BROOKE: Note to self-this is where to update the FNDDS codes for our food categories
* See Appendix H in 2017-2018 FNDDS Documentation

tostring foodcode1, replace
gen foodcode=.

* 1) dairy
replace foodcode=1 if substr(foodcode1,1,1)=="1" & codenot1112==0

* 2) fruit (total)
replace foodcode=2 if substr(foodcode1,1,1)=="6" & codenot1112==0

* 3) fruit excluding juice
replace foodcode=3 if (substr(foodcode1,1,2)=="61" | substr(foodcode1,1,2)=="62" | substr(foodcode1,1,2)=="63") & codenot1112==0

* 300) fruit juice
replace foodcode=300 if substr(foodcode1,1,2)=="64" & codenot1112==0

* 4) grains (total)
replace foodcode=4 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 5) refined grains
replace foodcode=5 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 6) whole grains
replace foodcode=6 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 7) legumes (total)
replace foodcode=7 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 8) vegetables (total)
replace foodcode=8 if substr(foodcode1,1,1)=="7" & codenot1112==0

* 9) dark-green vegetables
replace foodcode=9 if substr(foodcode1,1,2)=="72" & codenot1112==0

* 10) legumes (vegetables)
replace foodcode=10 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 11) other vegetables
replace foodcode=11 if substr(foodcode1,1,2)=="75" & codenot1112==0

* 12) red and orange vegetables
replace foodcode=12 if (substr(foodcode1,1,2)=="73" | substr(foodcode1,1,2)=="74") & codenot1112==0

* 13) starchy vegetables
replace foodcode=13 if substr(foodcode1,1,2)=="71" & codenot1112==0

* 14) vegetables excluding starchy
replace foodcode=14 if (substr(foodcode1,1,2)=="72" | substr(foodcode1,1,2)=="73" | substr(foodcode1,1,2)=="74" | substr(foodcode1,1,2)=="75") & codenot1112==0

* 15) eggs
replace foodcode=15 if substr(foodcode1,1,1)=="3" & codenot1112==0

* 16) legumes (protein)
replace foodcode=16 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 17) nuts and seeds
replace foodcode=17 if (substr(foodcode1,1,2)=="42" | substr(foodcode1,1,2)=="43" | substr(foodcode1,1,2)=="44") & codenot1112==0

* 18) processed meat
replace foodcode=18 if substr(foodcode1,1,2)=="25" & codenot1112==0

* 19) poultry
replace foodcode=19 if substr(foodcode1,1,2)=="24" & codenot1112==0

* 20) red meat
replace foodcode=20 if (substr(foodcode1,1,2)=="20" | substr(foodcode1,1,2)=="21" | substr(foodcode1,1,2)=="22" | substr(foodcode1,1,2)=="23") & codenot1112==0

* 21) seafood
replace foodcode=21 if substr(foodcode1,1,2)=="26" & codenot1112==0

* 22) soy foods
replace foodcode=22 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy>0

* 23) oils
replace foodcode=23 if substr(foodcode1,1,2)=="82" & codenot1112==0

* 24) added sugars
replace foodcode=24 if substr(foodcode1,1,2)=="91" & codenot1112==0

* 25) ssb
replace foodcode=25 if substr(foodcode1,1,2)=="92" & codenot1112==0

* 26) saturated fat
replace foodcode=26 if substr(foodcode1,1,2)=="81" & codenot1112==0

* everything else
replace foodcode=27 if foodcode==. & codenot1112==0
																					

*Categorize non-FNDDS-coded foods
*See FAFH nutrient data codebook

* 1) dairy
replace foodcode=1 if inlist(usdafoodcat1, 1) & codenot1112==1

* 2) fruit (total)
replace foodcode=2 if (inlist(usdafoodcat2, 60) | inlist(usdafoodcat4, 7002, 7004, 7006)) & codenot1112==1

* 3) fruit excluding juice
replace foodcode=3 if inlist(usdafoodcat2, 60) & codenot1112==1

* 300) fruit juice
replace foodcode=300 if inlist(usdafoodcat4, 7002, 7004, 7006) & codenot1112==1

* 4) grains (total)
replace foodcode=4 if inlist(usdafoodcat1, 4) & codenot1112==1

* 5) refined grains
replace foodcode=5 if inlist(usdafoodcat1, 4) & codenot1112==1

* 6) whole grains
replace foodcode=6 if inlist(usdafoodcat1, 4) & codenot1112==1

* 7) legumes (total)
replace foodcode=7 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 8) vegetables (total)
replace foodcode=8 if inlist(usdafoodcat2, 64, 68) & codenot1112==1

* 9) dark-green vegetables
replace foodcode=9 if inlist(usdafoodcat4, 6408) & codenot1112==1

* 10) legumes (vegetables)
replace foodcode=10 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 11) other vegetables
replace foodcode=11 if inlist(usdafoodcat4, 6410, 6412, 6414, 6416, 6420) & codenot1112==1

* 12) red and orange vegetables
replace foodcode=12 if inlist(usdafoodcat4, 6402, 6404, 6406) & codenot1112==1

* 13) starchy vegetables
replace foodcode=13 if (inlist(usdafoodcat2, 68) | inlist(usdafoodcat4, 6418)) & codenot1112==1

* 14) vegetables excluding starchy
replace foodcode=14 if inlist(usdafoodcat4, 6402, 6404, 6406, 6408, 6410, 6412, 6414, 6416, 6420) & codenot1112==1

* 15) eggs
replace foodcode=15 if inlist(usdafoodcat2, 25) & codenot1112==1

* 16) legumes (protein)
replace foodcode=16 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 17) nuts and seeds
replace foodcode=17 if inlist(usdafoodcat4, 2804) & codenot1112==1

* 18) processed meat
replace foodcode=18 if inlist(usdafoodcat2, 26) & codenot1112==1

* 19) poultry
replace foodcode=19 if inlist(usdafoodcat2, 22) & codenot1112==1

* 20) red meat
replace foodcode=20 if inlist(usdafoodcat4, 2002, 2004, 2006, 2008, 2010) & codenot1112==1

* 21) seafood
replace foodcode=21 if inlist(usdafoodcat2, 24) & codenot1112==1

* 22) soy foods
replace foodcode=22 if inlist(usdafoodcat4, 2806) & codenot1112==1

* 23) oils
replace foodcode=23 if inlist(usdafoodcat4, 8012) & codenot1112==1

* 24) added sugars
replace foodcode=24 if inlist(usdafoodcat2, 88) & codenot1112==1

* 25) ssb
replace foodcode=25 if inlist(usdafoodcat2, 72) & codenot1112==1

* 26) saturated fat
replace foodcode=26 if inlist(usdafoodcat4, 8002, 8004, 8006, 8008, 8010) & codenot1112==1
																					
* everything else
replace foodcode=27 if foodcode==.

*Merge with cost file
*merge 1:1 mergevar using "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh_itemcost"
merge 1:1 mergevar using "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fafh_itemcost"
drop _merge

drop  usdafoodcat1 usdafoodcat2 usdafoodcat4 mergevar foodcode1 pf_soy


********************************************************************************
*FAFH: MERGE WITH HOUSEHOLD DATA
********************************************************************************

bysort hhnum foodcode: egen grams_tot=total(grams) if cost_g!=.
gen coef=grams/grams_tot

bysort hhnum foodcode: gen cost_g_temp=cost_g*coef
bysort hhnum foodcode: egen cost_g_adj=total(cost_g_temp)
	*replace cost_g_adj=. if cost_g_adj==0

egen unique=concat(hhnum foodcode)
destring unique, replace
duplicates drop unique, force

keep hhnum foodcode cost_g_adj

rename cost_g_adj cost_fafh

reshape wide cost_fafh, i(hhnum) j(foodcode)

*merge m:1 hhnum using "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_household_puf"
merge m:1 hhnum using "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_household_puf"
gen sample_fafh=0
replace sample_fafh=1 if _merge==3
drop _merge

keep hhnum-cost_fafh27 tsstrata tspsu hhwgt sample_fafh

egen cost_tot_fafh=rowtotal(cost_fafh1-cost_fafh27)

*save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh", replace
save "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fafh", replace


********************************************************************************
*FAFH: ANALYSIS
********************************************************************************
clear
*use "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fafh"

svyset [w=hhwgt], psu(tspsu) strata(tsstrata) singleunit(centered)

*putexcel set "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Results\Results", sheet ("Byfood_amt_away_fap") modify
*putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

putexcel set "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Results/Results_bmb", sheet ("Byfood_amt_away_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fafh1-cost_fafh27 cost_tot_fafh{
	capture quietly svy, subpop(sample_fafh): reg `var'
	local k=`k'+1
	di `k'
	capture quietly putexcel A`k'=(e(depvar)) B`k'=(e(N_sub)) C`k'=_b[_cons] D`k'=_se[_cons]
	scalar	lb=_b[_cons]-invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel E`k'=(lb)
	scalar	ub=_b[_cons]+invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel F`k'=(ub)
}

*##############################################################################*

********************************************************************************
*FAH: ESTIMATE COST PER GRAM OF EACH FOOD
********************************************************************************
clear
*use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fahitem_puf"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_fahitem_puf"


*Format variables
keep hhnum eventid itemnum itemdesc totgramsunadj totgramsunadjimp totitemexp

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

replace totgramsunadj=totgramsunadjimp if totgramsunadj==.
rename totgramsunadj gramstotal
drop totgramsunadjimp

rename itemdesc desc
rename gramstotal grams
rename totitemexp cost

replace cost=. if cost==-996

format desc %60s

*Estimate cost per gram of each food
gen cost_g=cost/grams

	*replace cost_g=. if cost_g==0
	*replace cost=. if cost==0

replace cost_g=0 if cost_g<0

*save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah_itemcost", replace
save "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fah_itemcost", replace



********************************************************************************
*FAH: MERGE ITEM COST WITH FOOD CATEGORIES
********************************************************************************
clear
*use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fahnutrients"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_fahnutrients"

*Format variables
keep hhnum eventid itemnum usdafoodcat1 usdafoodcat2 usdafoodcat4 foodcode codenot1112 pf_soy
rename foodcode foodcode1

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

* Categorize FNDDS-coded foods

* BROOKE: Note to self-this is where to update the FNDDS codes for our food categories
* See Appendix H in 2017-2018 FNDDS Documentation


tostring foodcode1, replace
gen foodcode=.

* 1) dairy
replace foodcode=1 if substr(foodcode1,1,1)=="1" & codenot1112==0

* 2) fruit (total)
replace foodcode=2 if substr(foodcode1,1,1)=="6" & codenot1112==0

* 3) fruit excluding juice
replace foodcode=3 if (substr(foodcode1,1,2)=="61" | substr(foodcode1,1,2)=="62" | substr(foodcode1,1,2)=="63") & codenot1112==0

* 300) fruit juice
replace foodcode=300 if substr(foodcode1,1,2)=="64" & codenot1112==0

* 4) grains (total)
replace foodcode=4 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 5) refined grains
replace foodcode=5 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 6) whole grains
replace foodcode=6 if substr(foodcode1,1,1)=="5" & codenot1112==0

* 7) legumes (total)
replace foodcode=7 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 8) vegetables (total)
replace foodcode=8 if substr(foodcode1,1,1)=="7" & codenot1112==0

* 9) dark-green vegetables
replace foodcode=9 if substr(foodcode1,1,2)=="72" & codenot1112==0

* 10) legumes (vegetables)
replace foodcode=10 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 11) other vegetables
replace foodcode=11 if substr(foodcode1,1,2)=="75" & codenot1112==0

* 12) red and orange vegetables
replace foodcode=12 if (substr(foodcode1,1,2)=="73" | substr(foodcode1,1,2)=="74") & codenot1112==0

* 13) starchy vegetables
replace foodcode=13 if substr(foodcode1,1,2)=="71" & codenot1112==0

* 14) vegetables excluding starchy
replace foodcode=14 if (substr(foodcode1,1,2)=="72" | substr(foodcode1,1,2)=="73" | substr(foodcode1,1,2)=="74" | substr(foodcode1,1,2)=="75") & codenot1112==0

* 15) eggs
replace foodcode=15 if substr(foodcode1,1,1)=="3" & codenot1112==0

* 16) legumes (protein)
replace foodcode=16 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy==0

* 17) nuts and seeds
replace foodcode=17 if (substr(foodcode1,1,2)=="42" | substr(foodcode1,1,2)=="43" | substr(foodcode1,1,2)=="44") & codenot1112==0

* 18) processed meat
replace foodcode=18 if substr(foodcode1,1,2)=="25" & codenot1112==0

* 19) poultry
replace foodcode=19 if substr(foodcode1,1,2)=="24" & codenot1112==0

* 20) red meat
replace foodcode=20 if (substr(foodcode1,1,2)=="20" | substr(foodcode1,1,2)=="21" | substr(foodcode1,1,2)=="22" | substr(foodcode1,1,2)=="23") & codenot1112==0

* 21) seafood
replace foodcode=21 if substr(foodcode1,1,2)=="26" & codenot1112==0

* 22) soy foods
replace foodcode=22 if substr(foodcode1,1,2)=="41" & codenot1112==0 & pf_soy>0

* 23) oils
replace foodcode=23 if substr(foodcode1,1,2)=="82" & codenot1112==0

* 24) added sugars
replace foodcode=24 if substr(foodcode1,1,2)=="91" & codenot1112==0

* 25) ssb
replace foodcode=25 if substr(foodcode1,1,2)=="92" & codenot1112==0

* 26) saturated fat
replace foodcode=26 if substr(foodcode1,1,2)=="81" & codenot1112==0

* everything else
replace foodcode=27 if foodcode==. & codenot1112==0
																					

*Categorize non-FNDDS-coded foods
*See FAFH nutrient data codebook

* 1) dairy
replace foodcode=1 if inlist(usdafoodcat1, 1) & codenot1112==1

* 2) fruit (total)
replace foodcode=2 if (inlist(usdafoodcat2, 60) | inlist(usdafoodcat4, 7002, 7004, 7006)) & codenot1112==1

* 3) fruit excluding juice
replace foodcode=3 if inlist(usdafoodcat2, 60) & codenot1112==1

* 300) fruit juice
replace foodcode=300 if inlist(usdafoodcat4, 7002, 7004, 7006) & codenot1112==1

* 4) grains (total)
replace foodcode=4 if inlist(usdafoodcat1, 4) & codenot1112==1

* 5) refined grains
replace foodcode=5 if inlist(usdafoodcat1, 4) & codenot1112==1

* 6) whole grains
replace foodcode=6 if inlist(usdafoodcat1, 4) & codenot1112==1

* 7) legumes (total)
replace foodcode=7 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 8) vegetables (total)
replace foodcode=8 if inlist(usdafoodcat2, 64, 68) & codenot1112==1

* 9) dark-green vegetables
replace foodcode=9 if inlist(usdafoodcat4, 6408) & codenot1112==1

* 10) legumes (vegetables)
replace foodcode=10 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 11) other vegetables
replace foodcode=11 if inlist(usdafoodcat4, 6410, 6412, 6414, 6416, 6420) & codenot1112==1

* 12) red and orange vegetables
replace foodcode=12 if inlist(usdafoodcat4, 6402, 6404, 6406) & codenot1112==1

* 13) starchy vegetables
replace foodcode=13 if (inlist(usdafoodcat2, 68) | inlist(usdafoodcat4, 6418)) & codenot1112==1

* 14) vegetables excluding starchy
replace foodcode=14 if inlist(usdafoodcat4, 6402, 6404, 6406, 6408, 6410, 6412, 6414, 6416, 6420) & codenot1112==1

* 15) eggs
replace foodcode=15 if inlist(usdafoodcat2, 25) & codenot1112==1

* 16) legumes (protein)
replace foodcode=16 if inlist(usdafoodcat4, 2802) & codenot1112==1

* 17) nuts and seeds
replace foodcode=17 if inlist(usdafoodcat4, 2804) & codenot1112==1

* 18) processed meat
replace foodcode=18 if inlist(usdafoodcat2, 26) & codenot1112==1

* 19) poultry
replace foodcode=19 if inlist(usdafoodcat2, 22) & codenot1112==1

* 20) red meat
replace foodcode=20 if inlist(usdafoodcat4, 2002, 2004, 2006, 2008, 2010) & codenot1112==1

* 21) seafood
replace foodcode=21 if inlist(usdafoodcat2, 24) & codenot1112==1

* 22) soy foods
replace foodcode=22 if inlist(usdafoodcat4, 2806) & codenot1112==1

* 23) oils
replace foodcode=23 if inlist(usdafoodcat4, 8012) & codenot1112==1

* 24) added sugars
replace foodcode=24 if inlist(usdafoodcat2, 88) & codenot1112==1

* 25) ssb
replace foodcode=25 if inlist(usdafoodcat2, 72) & codenot1112==1

* 26) saturated fat
replace foodcode=26 if inlist(usdafoodcat4, 8002, 8004, 8006, 8008, 8010) & codenot1112==1
																					
* everything else
replace foodcode=27 if foodcode==.

*Merge with cost file
*merge 1:1 mergevar using "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah_itemcost"
merge 1:1 mergevar using "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fah_itemcost"

drop _merge

drop usdafoodcat1 usdafoodcat2 usdafoodcat4 mergevar foodcode1 pf_soy


********************************************************************************
*FAH: MERGE WITH HOUSEHOLD DATA
********************************************************************************

bysort hhnum foodcode: egen grams_tot=total(grams) if cost_g!=.
gen coef=grams/grams_tot

bysort hhnum foodcode: gen cost_g_temp=cost_g*coef
bysort hhnum foodcode: egen cost_g_adj=total(cost_g_temp)
	*replace cost_g_adj=. if cost_g_adj==0

egen unique=concat(hhnum foodcode)
destring unique, replace
duplicates drop unique, force

keep hhnum foodcode cost_g_adj

rename cost_g_adj cost_fah

reshape wide cost_fah, i(hhnum) j(foodcode)

*merge m:1 hhnum using "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_household_puf"
merge m:1 hhnum using "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/faps_household_puf"

gen sample_fah=0
replace sample_fah=1 if _merge==3
drop _merge

keep hhnum-cost_fah27 tsstrata tspsu hhwgt sample_fah

egen cost_tot_fah=rowtotal(cost_fah1-cost_fah27)

*save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah", replace
save "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fah", replace


********************************************************************************
*FAH: ANALYSIS
********************************************************************************
clear
*use "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah"
use "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Scratch/faps_fah"

svyset [w=hhwgt], psu(tspsu) strata(tsstrata) singleunit(centered)

*putexcel set "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Results\Results", sheet ("Byfood_amt_home_fap") modify
*putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

putexcel set "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Results/Results_bmb", sheet ("Byfood_amt_home_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fah1-cost_fah27 cost_tot_fah{
	capture quietly svy, subpop(sample_fah): reg `var'
	local k=`k'+1
	di `k'
	capture quietly putexcel A`k'=(e(depvar)) B`k'=(e(N_sub)) C`k'=_b[_cons] D`k'=_se[_cons]
	scalar	lb=_b[_cons]-invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel E`k'=(lb)
	scalar	ub=_b[_cons]+invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel F`k'=(ub)
}
