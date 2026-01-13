#script to create 2500 kcal veg pattern with foods, and lca impacts (just in case) 
##for human cost analysis
#open in human cost R project
setwd("./data")
pattern_2500_dy_us <- read.csv("./out/pattern_2500_dy_us.csv") 
fped_crosswalk_eat <- read.csv("./in/fped_crosswalk_eat.csv")

diet_impacts_us <- merge(fped_crosswalk_eat, pattern_2500_dy_us, by= "dga_subgrp") #merging patterns with foods
library(plyr) #checking to make sure # of foods in merged dataframe match those in FPED crosswalk
  groups1 <- count(fped_crosswalk_eat$dga_subgrp)
  groups2 <- count(diet_impacts_us$dga_subgrp)
    stopifnot(identical(groups1,groups2)) #script will throw an error if the groups dont match.
      rm(groups1, groups2)
diet_impacts_us <- diet_impacts_us[setdiff(names(diet_impacts_us), #removing extraneous columns 
                                             c("X", "X.y" , "X.x","food_grp.x"))]    
  diet_impacts_us <- rename(diet_impacts_us, c("food_grp.y"= "food_grp")) #renaming food group col back to original


#Create diets with foods on 100g basis
diet_impacts_us$ddiet_fpe_2500 <- NA #creating var for daily 2500 kcal pattern by food in fpe amounts
diet_impacts_us$ddiet_fpe_2500 <- diet_impacts_us$fpe_dy_2500*diet_impacts_us$prop_dga_subgrp
diet_impacts_us$ddiet_2500 <-  diet_impacts_us$ddiet_fpe_2500*diet_impacts_us$FPED_CF #creating var for daily patterns by food in 100g amounts
diet_impacts_us <- subset(diet_impacts_us, select = 
                             -c(fpe_dy_2500)) #removing scaling vector 

#Create gram amounts for bottom up g recommendations
diet_impacts_us$ddiet_2500_grams <- diet_impacts_us$ddiet_2500*100

#Create gram sums by subgroup --- to be exported 
grams_by_subgrp_us <- tapply(diet_impacts_us$ddiet_2500_grams, diet_impacts_us$dga_subgrp, sum)
grams_by_subgrp_us <- as.data.frame(grams_by_subgrp_us)
rename(grams_by_subgrp_us, c("grams_by_subgrp_us" = "grams_2500_us"))


#Add new column for food group proportions on a mass basis
diet_impacts_us <-  ddply(diet_impacts_us, .(food_grp), transform, grams_grp_tot 
                           = sum(ddiet_2500_grams)) #making new column with grp gram totals
diet_impacts_us$prop_grp_grams <- diet_impacts_us$ddiet_2500_grams/diet_impacts_us$grams_grp_tot 
tapply(diet_impacts_us$prop_grp_grams, diet_impacts_us$food_grp, sum) #checking that group props sum to 1
diet_impacts_us <- diet_impacts_us[setdiff(names(diet_impacts_us), #removing scaling column
                                             c("grams_grp_tot"))]  
#Add new column for food subgroup proportions on a mass basis
diet_impacts_us <-  ddply(diet_impacts_us, .(dga_subgrp), transform, grams_subgrp_tot 
                           = sum(ddiet_2500_grams)) #making new column with grp gram totals
diet_impacts_us$prop_subgrp_grams <- diet_impacts_us$ddiet_2500_grams/diet_impacts_us$grams_subgrp_tot 
tapply(diet_impacts_us$prop_subgrp_grams, diet_impacts_us$dga_subgrp, sum) #checking that group props sum to 1
diet_impacts_us <- diet_impacts_us[setdiff(names(diet_impacts_us), #removing scaling column
                                             c("grams_subgrp_tot"))]  

colnames(diet_impacts_us) #reordering columns in logical order
diet_impacts_us <- diet_impacts_us[c("FNDDS_food_code", "FNDDS_food_code_descr" , "food_item_cluster", 
                                       "rep_food", "food_grp"  ,   "dga_subgrp" , "commodity" ,  "ddiet_fpe_2500",  
                                       "prop_dga_subgrp" , "ddiet_2500" , "ddiet_2500_grams" , "prop_grp_grams" ,
                                       "prop_subgrp_grams", "FPED" , "FPED_CF" ,  "gwp_100g", "od_100g", "htnc_100g" ,
                                       "htc_100g" , "pm_100g","irh_100g","ire_100g", "pof_100g" , "acid_100g" ,
                                       "teu_100g", "feu_100g" , "meu_100g" , "feco_100g" ,"lu_100g" ,"wd_100g" ,"md_100g")]

#writing subgroup gram totals out
write.csv(grams_by_subgrp_us, file='./out/grams_by_subgrp_us.csv')

#writing patterns with foods and environmental impacts out
write.csv(diet_impacts_us, file='./out/diet_env_impacts_us.csv')

#rm(list=ls())
