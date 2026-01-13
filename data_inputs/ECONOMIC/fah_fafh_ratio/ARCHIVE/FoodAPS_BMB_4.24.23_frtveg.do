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

* 1) fruit (total)
replace foodcode=1 if substr(foodcode1,1,1)=="6" & codenot1112==0

* 2) vegetables (total)
replace foodcode=2 if substr(foodcode1,1,1)=="7" & codenot1112==0

* 3) everything else
replace foodcode=3 if foodcode==. & codenot1112==0

* CHECK
tab foodcode																			

*Categorize non-FNDDS-coded foods
*See FAFH nutrient data codebook

* 1) fruit (total)
replace foodcode=1 if (inlist(usdafoodcat2, 60) | inlist(usdafoodcat4, 7002, 7004, 7006)) & codenot1112==1

* 2) vegetables (total)
replace foodcode=2 if inlist(usdafoodcat2, 64, 68) & codenot1112==1

* 3) everything else
replace foodcode=3 if foodcode==.

* CHECK
tab foodcode

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

keep hhnum-cost_fafh3 tsstrata tspsu hhwgt sample_fafh

egen cost_tot_fafh=rowtotal(cost_fafh1-cost_fafh3)

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

putexcel set "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Results/Results_bmb_frtveg", sheet ("Byfood_amt_away_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fafh1-cost_fafh3 cost_tot_fafh{
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

* 1) fruit (total)
replace foodcode=1 if substr(foodcode1,1,1)=="6" & codenot1112==0

* 2) vegetables (total)
replace foodcode=2 if substr(foodcode1,1,1)=="7" & codenot1112==0

* 3) everything else
replace foodcode=3 if foodcode==. & codenot1112==0

* CHECK
tab foodcode																			

*Categorize non-FNDDS-coded foods
*See FAFH nutrient data codebook

* 1) fruit (total)
replace foodcode=1 if (inlist(usdafoodcat2, 60) | inlist(usdafoodcat4, 7002, 7004, 7006)) & codenot1112==1

* 2) vegetables (total)
replace foodcode=2 if inlist(usdafoodcat2, 64, 68) & codenot1112==1

* 3) everything else
replace foodcode=3 if foodcode==.

* CHECK
tab foodcode

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

keep hhnum-cost_fah3 tsstrata tspsu hhwgt sample_fah

egen cost_tot_fah=rowtotal(cost_fah1-cost_fah3)

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

putexcel set "/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/planning/Methods of estimating FAFH to FAH ratio/Brooke/Results/Results_bmb_frtveg", sheet ("Byfood_amt_home_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fah1-cost_fah3 cost_tot_fah{
	capture quietly svy, subpop(sample_fah): reg `var'
	local k=`k'+1
	di `k'
	capture quietly putexcel A`k'=(e(depvar)) B`k'=(e(N_sub)) C`k'=_b[_cons] D`k'=_se[_cons]
	scalar	lb=_b[_cons]-invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel E`k'=(lb)
	scalar	ub=_b[_cons]+invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel F`k'=(ub)
}
