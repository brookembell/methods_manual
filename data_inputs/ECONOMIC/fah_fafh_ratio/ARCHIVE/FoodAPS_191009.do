********************************************************************************
*FAFH: ESTIMATE COST PER GRAM OF EACH FOOD
********************************************************************************
clear
use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fafhitem_puf"

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

save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh_itemcost", replace


********************************************************************************
*FAFH: MERGE ITEM COST WITH FOOD CATEGORIES
********************************************************************************
clear
use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fafhnutrient_puf"

*Format variables
keep hhnum eventid itemnum usdafoodcat2 foodcode codenot1112
rename foodcode foodcode1

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

*Categorize FNDDS-coded foods
tostring foodcode1, replace
gen foodcode=.
replace foodcode=10 if substr(foodcode1,1,1)=="1" & codenot1112==0																		/*dairy*/
replace foodcode=11 if (substr(foodcode1,1,2)=="21" | substr(foodcode1,1,2)=="22" | substr(foodcode1,1,2)=="23") & codenot1112==0		/*meat*/
replace foodcode=12 if substr(foodcode1,1,2)=="24" & codenot1112==0																		/*poultry*/
replace foodcode=13 if substr(foodcode1,1,2)=="26" & codenot1112==0																		/*seafood*/
replace foodcode=14 if substr(foodcode1,1,1)=="3" & codenot1112==0																		/*eggs*/
replace foodcode=15 if (substr(foodcode1,1,2)=="25" | substr(foodcode1,1,2)=="27" | substr(foodcode1,1,2)=="28") & codenot1112==0	 	/*meat, poultry, and seafood*/
replace foodcode=16 if substr(foodcode1,1,1)=="5" & codenot1112==0	 																	/*grains*/ 
replace foodcode=17 if (substr(foodcode1,1,1)=="4" | substr(foodcode1,1,1)=="6" | substr(foodcode1,1,1)=="7") & codenot1112==0	  		/*f&v*/
replace foodcode=18 if (substr(foodcode1,1,2)=="92" | substr(foodcode1,1,2)=="94" | substr(foodcode1,1,2)=="95") & codenot1112==0	   	/*beverages*/
replace foodcode=19 if substr(foodcode1,1,2)=="91" & codenot1112==0	 																	/*sweets*/		
replace foodcode=20 if substr(foodcode1,1,1)=="8" & codenot1112==0		 																/*fats and oils*/
replace foodcode=21 if foodcode==. & codenot1112==0																						/*other*/

*Categorize non-FNDDS-coded foods
replace foodcode=10 if inlist(usdafoodcat2,10,12,14,16,18) & codenot1112==1							/*dairy*/
replace foodcode=11 if inlist(usdafoodcat2,20) & codenot1112==1										/*meat*/
replace foodcode=12 if inlist(usdafoodcat2,22,26) & codenot1112==1									/*poultry*/
replace foodcode=13 if inlist(usdafoodcat2,24) & codenot1112==1										/*seafood*/
replace foodcode=14 if inlist(usdafoodcat2,25) & codenot1112==1										/*eggs*/
replace foodcode=15 if inlist(usdafoodcat2,30) & codenot1112==1										/*meat, poultry, and seafood*/
replace foodcode=16 if inlist(usdafoodcat2,32,34,35,36,40,42,44,46,48,50,52,55) & codenot1112==1	/*grains*/ 
replace foodcode=17 if inlist(usdafoodcat2,28,60,64,68,70) & codenot1112==1							/*f&v*/
replace foodcode=18 if inlist(usdafoodcat2,71,72,73,75,77,78) & codenot1112==1						/*beverages*/
replace foodcode=19 if inlist(usdafoodcat2,57,58,88) & codenot1112==1								/*sweets*/		
replace foodcode=20 if inlist(usdafoodcat2,80) & codenot1112==1										/*fats and oils*/
replace foodcode=21 if inlist(usdafoodcat2,37,38,54,84,90,94,99,.) & codenot1112==1					/*other*/
replace foodcode=21 if foodcode==.

*Merge with cost file
merge 1:1 mergevar using "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh_itemcost"
drop _merge

drop usdafoodcat2 mergevar foodcode1


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

merge m:1 hhnum using "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_household_puf"
gen sample_fafh=0
replace sample_fafh=1 if _merge==3
drop _merge

keep hhnum-cost_fafh21 tsstrata tspsu hhwgt sample_fafh

egen cost_tot_fafh=rowtotal(cost_fafh10-cost_fafh21)

save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh", replace

********************************************************************************
*FAFH: ANALYSIS
********************************************************************************
clear
use "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fafh"

svyset [w=hhwgt], psu(tspsu) strata(tsstrata) singleunit(centered)

putexcel set "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Results\Results", sheet ("Byfood_amt_away_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fafh10-cost_fafh21 cost_tot_fafh{
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
use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fahitem_puf"

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

save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah_itemcost", replace


********************************************************************************
*FAH: MERGE ITEM COST WITH FOOD CATEGORIES
********************************************************************************
clear
use "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_fahnutrients"

*Format variables
keep hhnum eventid itemnum usdafoodcat2 foodcode codenot1112
rename foodcode foodcode1

replace eventid=eventid*10 if eventid<10000

tostring hhnum eventid itemnum, replace
egen mergevar=concat(hhnum eventid itemnum)
destring hhnum itemnum mergevar, replace
format mergevar %15.0f
drop eventid itemnum

*Categorize FNDDS-coded foods
tostring foodcode1, replace
gen foodcode=.
replace foodcode=10 if substr(foodcode1,1,1)=="1" & codenot1112==0																		/*dairy*/
replace foodcode=11 if (substr(foodcode1,1,2)=="21" | substr(foodcode1,1,2)=="22" | substr(foodcode1,1,2)=="23") & codenot1112==0		/*meat*/
replace foodcode=12 if substr(foodcode1,1,2)=="24" & codenot1112==0																		/*poultry*/
replace foodcode=13 if substr(foodcode1,1,2)=="26" & codenot1112==0																		/*seafood*/
replace foodcode=14 if substr(foodcode1,1,1)=="3" & codenot1112==0																		/*eggs*/
replace foodcode=15 if (substr(foodcode1,1,2)=="25" | substr(foodcode1,1,2)=="27" | substr(foodcode1,1,2)=="28") & codenot1112==0	 	/*meat, poultry, and seafood*/
replace foodcode=16 if substr(foodcode1,1,1)=="5" & codenot1112==0	 																	/*grains*/ 
replace foodcode=17 if (substr(foodcode1,1,1)=="4" | substr(foodcode1,1,1)=="6" | substr(foodcode1,1,1)=="7") & codenot1112==0	  		/*f&v*/
replace foodcode=18 if (substr(foodcode1,1,2)=="92" | substr(foodcode1,1,2)=="94" | substr(foodcode1,1,2)=="95") & codenot1112==0	   	/*beverages*/
replace foodcode=19 if substr(foodcode1,1,2)=="91" & codenot1112==0	 																	/*sweets*/		
replace foodcode=20 if substr(foodcode1,1,1)=="8" & codenot1112==0		 																/*fats and oils*/
replace foodcode=21 if foodcode==. & codenot1112==0																						/*other*/

*Categorize non-FNDDS-coded foods
replace foodcode=10 if inlist(usdafoodcat2,10,12,14,16,18) & codenot1112==1							/*dairy*/
replace foodcode=11 if inlist(usdafoodcat2,20) & codenot1112==1										/*meat*/
replace foodcode=12 if inlist(usdafoodcat2,22,26) & codenot1112==1									/*poultry*/
replace foodcode=13 if inlist(usdafoodcat2,24) & codenot1112==1										/*seafood*/
replace foodcode=14 if inlist(usdafoodcat2,25) & codenot1112==1										/*eggs*/
replace foodcode=15 if inlist(usdafoodcat2,30) & codenot1112==1										/*meat, poultry, and seafood*/
replace foodcode=16 if inlist(usdafoodcat2,32,34,35,36,40,42,44,46,48,50,52,55) & codenot1112==1	/*grains*/ 
replace foodcode=17 if inlist(usdafoodcat2,28,60,64,68,70) & codenot1112==1							/*f&v*/
replace foodcode=18 if inlist(usdafoodcat2,71,72,73,75,77,78) & codenot1112==1						/*beverages*/
replace foodcode=19 if inlist(usdafoodcat2,57,58,88) & codenot1112==1								/*sweets*/		
replace foodcode=20 if inlist(usdafoodcat2,80) & codenot1112==1										/*fats and oils*/
replace foodcode=21 if inlist(usdafoodcat2,37,38,54,84,90,94,99,.) & codenot1112==1					/*other*/
replace foodcode=21 if foodcode==.

*Merge with cost file
merge 1:1 mergevar using "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah_itemcost"
drop _merge

drop usdafoodcat2 mergevar foodcode1


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

merge m:1 hhnum using "C:\Users\zachc\Dropbox\Data\FoodAPS\Data\faps_household_puf"
gen sample_fah=0
replace sample_fah=1 if _merge==3
drop _merge

keep hhnum-cost_fah21 tsstrata tspsu hhwgt sample_fah

egen cost_tot_fah=rowtotal(cost_fah10-cost_fah21)

save "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah", replace


********************************************************************************
*FAH: ANALYSIS
********************************************************************************
clear
use "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Code\Scratch\faps_fah"

svyset [w=hhwgt], psu(tspsu) strata(tsstrata) singleunit(centered)

putexcel set "C:\Users\zachc\Dropbox\Projects\Food Waste Cost\Results\Results", sheet ("Byfood_amt_home_fap") modify
putexcel A1=("food") B1=("n") C1=("mean") D1=("se") E1=("lb") F1=("ub")

local k=1
foreach var of varlist cost_fah10-cost_fah21 cost_tot_fah{
	capture quietly svy, subpop(sample_fah): reg `var'
	local k=`k'+1
	di `k'
	capture quietly putexcel A`k'=(e(depvar)) B`k'=(e(N_sub)) C`k'=_b[_cons] D`k'=_se[_cons]
	scalar	lb=_b[_cons]-invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel E`k'=(lb)
	scalar	ub=_b[_cons]+invttail(e(df_r),0.025)*_se[_cons]
	capture quietly putexcel F`k'=(ub)
}
