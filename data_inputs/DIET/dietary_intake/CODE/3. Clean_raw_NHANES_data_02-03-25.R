# PART 1: CLEAN RAW NHANES 2015-2018 DATASETS
# AUTHOR: BROOKE BELL
# DATE: 02-03-25

# STEP 0: SET-UP -----

rm(list=ls())

# load packages
library(foreign)
library(survey)
library(tidyverse)
library(psych)
library(haven)
library(readxl)

# STEP 1: INDIVIDUAL-LEVEL FOOD INTAKE -----

# the names of the raw inputs are wrong...oh well, shouldn't matter

# 2015-2016 diet data (i)

# foods day 1
foods_i1_nutrients <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr1iff_i.sas7bdat")
foods_i1_whole <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr1iff_1516.sas7bdat")

# join
foods_i1 <- left_join(foods_i1_whole, foods_i1_nutrients) %>% mutate(nhanes_cycle = "2015-2016")

# foods day 2
foods_i2_nutrients <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr2iff_i.sas7bdat")
foods_i2_whole <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr2iff_1516.sas7bdat")

# join
foods_i2 <- left_join(foods_i2_whole, foods_i2_nutrients) %>% mutate(nhanes_cycle = "2015-2016")

# 2017-2018 diet data (j)

# foods day 1
foods_j1_nutrients <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr1iff_j.sas7bdat")
foods_j1_whole <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr1iff_1718.sas7bdat")

#join
foods_j1 <- left_join(foods_j1_whole, foods_j1_nutrients) %>% mutate(nhanes_cycle = "2017-2018")

# foods day 2
foods_j2_nutrients <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr2iff_j.sas7bdat")
foods_j2_whole <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr2iff_1718.sas7bdat")

# join
foods_j2 <- left_join(foods_j2_whole, foods_j2_nutrients) %>% mutate(nhanes_cycle = "2017-2018")

# create day 1 and 2 datasets
foods_day1 <- rbind(foods_i1, foods_j1) %>% 
  mutate(foodsource = ifelse(DR1FS == 1, "Grocery", "Other"), # create food source variable
         foodsource = replace_na(foodsource, "Other"), # replace NAs with "other" (applies to tap water and breast milk)
         dayrec = 1) # day1

foods_day2 <- rbind(foods_i2, foods_j2) %>% 
  mutate(foodsource = ifelse(DR2FS == 1, "Grocery", "Other"), # create food source variable
         foodsource = replace_na(foodsource, "Other"), # replace NAs with "other" (applies to tap water and breast milk)
         dayrec = 2) 

# read in meat data
meat_day1 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/meat_day1.rds")
meat_day2 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/meat_day2.rds")

foods_day1_ <- left_join(foods_day1, meat_day1, by = c("SEQN", "DR1ILINE"))
foods_day2_ <- left_join(foods_day2, meat_day2, by = c("SEQN", "DR2ILINE"))

# check
foods_day1_ %>% select(SEQN, DR1ILINE, DR1I_PF_MPS_TOTAL, DR1I_PF_SEAFD_HI, DR1I_PF_SEAFD_LOW, total_redmeat_new, total_poultry_new) %>% View()
foods_day1_ %>% filter(DR1I_PF_ORGAN > 0) %>% select(SEQN, DR1ILINE, DR1I_PF_MPS_TOTAL, DR1I_PF_SEAFD_HI, DR1I_PF_SEAFD_LOW, total_redmeat_new, total_poultry_new) %>% View()


# Calculate amount of intake for each dietary factor
# for day 1 and day 2
# by SEQN and foodsource

# first need to create diet variables that are combinations of 2+ vars

# day 1
foods_day1_1 <- foods_day1_ %>% 
  
  rowwise() %>% 
  
  rename(sat_fat = DR1ISFAT,
         p_fat = DR1IPFAT,
         sodium = DR1ISODI,
         gr_refined = DR1I_G_REFINED,
         gr_whole = DR1I_G_WHOLE,
         added_sugar = DR1I_ADD_SUGARS,
         fruit_juice = DR1I_F_JUICE,
         fiber = DR1IFIBE,
         veg_dg = DR1I_V_DRKGR,
         veg_oth = DR1I_V_OTHER,
         veg_ro = DR1I_V_REDOR_TOTAL,
         veg_sta = DR1I_V_STARCHY_TOTAL,
         veg_leg = DR1I_V_LEGUMES,
         oil = DR1I_OILS,
         pf_egg = DR1I_PF_EGGS,
         pf_ns = DR1I_PF_NUTSDS,
         pf_soy = DR1I_PF_SOY,
         pf_poultry = DR1I_PF_POULT,
         pf_redm = DR1I_PF_MEAT,
         pf_leg = DR1I_PF_LEGUMES,
         kcal = DR1IKCAL,
         
         pf_redm_tot = total_redmeat_new,
         pf_poultry_tot = total_poultry_new,
         fruit_tot = DR1I_F_TOTAL,
         dairy_tot = DR1I_D_TOTAL,
         gr_tot = DR1I_G_TOTAL
         
         ) %>% 
  
  mutate(sea_omega3_fa = sum(DR1IP226, DR1IP205),
         veg_exc_sta = sum(veg_dg, veg_ro, veg_oth),
         fruit_exc_juice = sum(DR1I_F_CITMLB, DR1I_F_OTHER),
         pf_pm = sum(DR1I_PF_CUREDMEAT, DR1I_PF_ORGAN),
         pf_seafood = sum(DR1I_PF_SEAFD_HI, DR1I_PF_SEAFD_LOW),
         pf_animal = sum(pf_poultry_tot, pf_redm_tot, pf_seafood, pf_egg),
         pf_plant = sum(pf_leg, pf_ns, pf_soy),
         
         leg_tot = sum(pf_leg, pf_soy), # doesn't include soy milk
         veg_tot = sum(veg_dg, veg_ro, veg_oth, veg_sta),
         pf_tot = sum(pf_egg, pf_redm_tot, pf_poultry_tot, pf_seafood,
                      pf_ns, leg_tot),
         
         # calculate added sugar as grams
         added_sugar_g = added_sugar * 4.2,
         
         # calculate AFS food category (grams)
         afs_tot = sum(oil, 
                       sat_fat,
                       added_sugar_g)
         
         ) %>%
  
  ungroup()

# create soy milk category
foods_day1_2 <- 
  foods_day1_1 %>% 
  mutate(dairy_soy = ifelse(str_detect(DESCRIPTION, "Soy milk") & dairy_tot > 0,
                                           dairy_tot, 
                                           0),
         dairy_cow = ifelse(str_detect(DESCRIPTION, "Soy milk", negate = TRUE) & dairy_tot > 0,
                            dairy_tot, 
                            0))
# check
foods_day1_2 %>% 
  filter(dairy_tot > 0) %>% 
  select(SEQN, DESCRIPTION, dairy_tot, dairy_soy, dairy_cow) %>% 
  View() #good

# day 2

foods_day2_1 <- foods_day2_ %>% 
  
  rowwise() %>% 
  
  rename(sat_fat = DR2ISFAT,
         p_fat = DR2IPFAT,
         sodium = DR2ISODI,
         gr_refined = DR2I_G_REFINED,
         gr_whole = DR2I_G_WHOLE,
         added_sugar = DR2I_ADD_SUGARS,
         fruit_juice = DR2I_F_JUICE,
         fiber = DR2IFIBE,
         veg_dg = DR2I_V_DRKGR,
         veg_oth = DR2I_V_OTHER,
         veg_ro = DR2I_V_REDOR_TOTAL,
         veg_sta = DR2I_V_STARCHY_TOTAL,
         veg_leg = DR2I_V_LEGUMES,
         oil = DR2I_OILS,
         pf_egg = DR2I_PF_EGGS,
         pf_ns = DR2I_PF_NUTSDS,
         pf_soy = DR2I_PF_SOY,
         pf_poultry = DR2I_PF_POULT,
         pf_redm = DR2I_PF_MEAT,
         pf_leg = DR2I_PF_LEGUMES,
         kcal = DR2IKCAL,
         
         pf_redm_tot = total_redmeat_new,
         pf_poultry_tot = total_poultry_new,
         fruit_tot = DR2I_F_TOTAL,
         dairy_tot = DR2I_D_TOTAL,
         gr_tot = DR2I_G_TOTAL
         
  ) %>% 
  
  mutate(sea_omega3_fa = sum(DR2IP226, DR2IP205),
         veg_exc_sta = sum(veg_dg, veg_ro, veg_oth),
         fruit_exc_juice = sum(DR2I_F_CITMLB, DR2I_F_OTHER),
         pf_pm = sum(DR2I_PF_CUREDMEAT, DR2I_PF_ORGAN),
         pf_seafood = sum(DR2I_PF_SEAFD_HI, DR2I_PF_SEAFD_LOW),
         pf_animal = sum(pf_poultry_tot, pf_redm_tot, pf_seafood, pf_egg),
         pf_plant = sum(pf_leg, pf_ns, pf_soy),
         
         leg_tot = sum(pf_leg, pf_soy), # doesn't include soy milk
         veg_tot = sum(veg_dg, veg_ro, veg_oth, veg_sta),
         pf_tot = sum(pf_egg, pf_redm_tot, pf_poultry_tot, pf_seafood,
                      pf_ns, leg_tot),
         
         # calculate added sugar as grams
         added_sugar_g = added_sugar * 4.2,
         
         # calculate AFS food category (grams)
         afs_tot = sum(oil, 
                       sat_fat,
                       added_sugar_g)
         
  ) %>%
  
  ungroup()

# create soy milk category
foods_day2_2 <- 
  foods_day2_1 %>% 
  mutate(dairy_soy = ifelse(str_detect(DESCRIPTION, "Soy milk") & dairy_tot > 0,
                            dairy_tot, 
                            0),
         dairy_cow = ifelse(str_detect(DESCRIPTION, "Soy milk", negate = TRUE) & dairy_tot > 0,
                            dairy_tot, 
                            0))
# check
foods_day2_2 %>% 
  filter(dairy_tot > 0) %>% 
  select(SEQN, DESCRIPTION, dairy_tot, dairy_soy, dairy_cow) %>% 
  View() #good


# export foods day 1 and day 2 for later use
write_rds(foods_day1_2, "in/ALL PILLARS/Dietary intake/clean data/foods_day1_clean.rds")
write_rds(foods_day2_2, "in/ALL PILLARS/Dietary intake/clean data/foods_day2_clean.rds")

# STEP 2: FOOD AND NUTRIENT INTAKE (SUMMARY) -----

rm(list=setdiff(ls(), c("foods_day1_2", "foods_day2_2")))

# QUICKLY HANDLE MEAT
meat_sum_day1 <- 
  foods_day1_2 %>% 
  group_by(SEQN) %>% 
  summarise(pf_redm_tot_1 = sum(pf_redm_tot),
            pf_poultry_tot_1 = sum(pf_poultry_tot))

meat_sum_day2 <- 
  foods_day2_2 %>% 
  group_by(SEQN) %>% 
  summarise(pf_redm_tot_2 = sum(pf_redm_tot),
            pf_poultry_tot_2 = sum(pf_poultry_tot))

# 2015-2016 diet data (i)

# demographic data
demo_i <- read_sas("in/ALL PILLARS/Dietary intake/raw data/demo_i.sas7bdat") %>% 
  select(SEQN, RIAGENDR, RIDRETH1, DMDEDUC2, INDFMPIR, RIDAGEYR)

# fped day 1
fped_i1 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr1tot_1516.sas7bdat") 

# fped day 2
fped_i2 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr2tot_1516.sas7bdat")

# join the two datasets
fped_i <- left_join(fped_i1, fped_i2)

# nutrients day 1
nutrient_i1 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr1tot_i.sas7bdat")

# nutrients day 2
nutrient_i2 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr2tot_i.sas7bdat")

# join the two datasets
nutrient_i <- full_join(nutrient_i1, nutrient_i2)

# Combine all datasets
nhanes1516 <-  
  fped_i %>% 
  left_join(nutrient_i) %>% 
  left_join(demo_i)

# 2017-2018 diet data (j)

# demographic data
demo_j <- read_sas("in/ALL PILLARS/Dietary intake/raw data/demo_j.sas7bdat") %>% 
  select(SEQN, RIAGENDR, RIDRETH1, DMDEDUC2, INDFMPIR, RIDAGEYR)

# fped day 1
fped_j1 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr1tot_1718.sas7bdat") 

# fped day 2
fped_j2 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_dr2tot_1718.sas7bdat")

# join the two datasets
fped_j <- left_join(fped_j1, fped_j2)

# nutrients day 1
nutrient_j1 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr1tot_j.sas7bdat")

# nutrients day 2
nutrient_j2 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/dr2tot_j.sas7bdat")

# join the two datasets
nutrient_j <- full_join(nutrient_j1, nutrient_j2)

# Combine all datasets
nhanes1718 <- fped_j %>% 
  left_join(nutrient_j) %>% 
  left_join(demo_j) 

# combine the two nhanes datasets

# first, change 2 variable names that don't match
nhanes1718 <- nhanes1718 %>% rename(DR1TWS = DR1TWSZ,
                                    DR2TWS = DR2TWSZ)

nhanes_comb <- rbind(nhanes1516, nhanes1718)

# combine with meat
nhanes_comb1 <- left_join(nhanes_comb, meat_sum_day1, by = "SEQN") %>% left_join(meat_sum_day2, by = "SEQN")

# import processed meat dataset
# pm <- read_sas("in/ALL PILLARS/Dietary intake/processed meat/out/meat_usual_intake.sas7bdat")
# 
# pm %>% select(contains("redmeat"))
# 
# pm1 <- pm %>% select(SEQN, total_redmeat, total_poultry, report) %>% 
#   rename(pf_redm_tot = total_redmeat,
#          pf_poultry_tot = total_poultry)
# 
# pm_wide <- pivot_wider(pm1, id_cols = SEQN,
#                        names_from = report,
#                        values_from = c("pf_redm_tot", "pf_poultry_tot"))

# merge with nhanescomb
# nhanes_comb1 <- left_join(nhanes_comb, pm_wide, by = "SEQN")

# create dairy variables
dairy_day1 <-
  foods_day1_2 %>% 
  group_by(SEQN) %>% 
  summarise(dairy_cow_1 = sum(dairy_cow),
            dairy_soy_1 = sum(dairy_soy))

dairy_day2 <-
  foods_day2_2 %>% 
  group_by(SEQN) %>% 
  summarise(dairy_cow_2 = sum(dairy_cow),
            dairy_soy_2 = sum(dairy_soy))

# merge with nhanes

dairy_bothdays <- full_join(dairy_day1, dairy_day2)

nhanes_comb2 <- nhanes_comb1 %>% left_join(dairy_bothdays, by = "SEQN")

# STEP 2b: CONSTRUCT DIETARY FACTORS -----

nhanes_comb3 <-
  nhanes_comb2 %>% 
  rename(kcal_1 = DR1TKCAL,
         kcal_2 = DR2TKCAL,
         
         sat_fat_1 = DR1TSFAT,
         sat_fat_2 = DR2TSFAT,
         
         sodium_1 = DR1TSODI,
         sodium_2 = DR2TSODI,
         
         gr_refined_1 = DR1T_G_REFINED,
         gr_refined_2 = DR2T_G_REFINED,
         
         gr_whole_1 = DR1T_G_WHOLE,
         gr_whole_2 = DR2T_G_WHOLE,
         
         added_sugar_1 = DR1T_ADD_SUGARS,
         added_sugar_2 = DR2T_ADD_SUGARS,
         
         fruit_tot_1 = DR1T_F_TOTAL,
         fruit_tot_2 = DR2T_F_TOTAL,
         
         fruit_juice_1 = DR1T_F_JUICE,
         fruit_juice_2 = DR2T_F_JUICE,
         
         fiber_1 = DR1TFIBE,
         fiber_2 = DR2TFIBE,
         
         dairy_tot_1 = DR1T_D_TOTAL,
         dairy_tot_2 = DR2T_D_TOTAL,
         
         veg_dg_1 = DR1T_V_DRKGR,
         veg_dg_2 = DR2T_V_DRKGR,
         
         veg_oth_1 = DR1T_V_OTHER,
         veg_oth_2 = DR2T_V_OTHER,
         
         veg_ro_1 = DR1T_V_REDOR_TOTAL,
         veg_ro_2 = DR2T_V_REDOR_TOTAL,
         
         veg_sta_1 = DR1T_V_STARCHY_TOTAL,
         veg_sta_2 = DR2T_V_STARCHY_TOTAL,
         
         # Beans, peas, and lentils  (legumes) computed as vegetables (cup eq.) 
         veg_leg_1 = DR1T_V_LEGUMES,
         veg_leg_2 = DR2T_V_LEGUMES,
         
         oil_1 = DR1T_OILS,
         oil_2 = DR2T_OILS,
         
         pf_egg_1 = DR1T_PF_EGGS,
         pf_egg_2 = DR2T_PF_EGGS,
         
         pf_ns_1 = DR1T_PF_NUTSDS,
         pf_ns_2 = DR2T_PF_NUTSDS,
         
         # soy only
         # Soy products, excluding calcium fortified soy milk (soymilk) 
         # and raw soybeans products (oz. eq.) 
         pf_soy_1 = DR1T_PF_SOY,
         pf_soy_2 = DR2T_PF_SOY,
         
         pf_poultry_1 = DR1T_PF_POULT,
         pf_poultry_2 = DR2T_PF_POULT,
         
         pf_redm_1 = DR1T_PF_MEAT,
         pf_redm_2 = DR2T_PF_MEAT,
         
         pf_pm_1 = DR1T_PF_CUREDMEAT,
         pf_pm_2 = DR2T_PF_CUREDMEAT,
         
         pf_organ_1 = DR1T_PF_ORGAN,
         pf_organ_2 = DR2T_PF_ORGAN,
         
         # Beans and Peas (legumes) computed as protein foods (oz. eq.) 
         pf_leg_1 = DR1T_PF_LEGUMES,
         pf_leg_2 = DR2T_PF_LEGUMES) %>% 
  
  rowwise() %>% 
  
  mutate(sea_omega3_fa_1 = sum(DR1TP226, DR1TP205),
         sea_omega3_fa_2 = sum(DR2TP226, DR2TP205),
         
         veg_exc_sta_1 = sum(veg_dg_1, veg_ro_1, veg_oth_1),
         veg_exc_sta_2 = sum(veg_dg_2, veg_ro_2, veg_oth_2),
         
         fruit_exc_juice_1 = sum(DR1T_F_CITMLB, DR1T_F_OTHER),
         fruit_exc_juice_2 = sum(DR2T_F_CITMLB, DR2T_F_OTHER),

         pufa_energy_1 = ((DR1TPFAT * 9) / kcal_1) * 100,
         pufa_energy_2 = ((DR2TPFAT * 9) / kcal_2) * 100,
         
         sfat_energy_1 = ((sat_fat_1 * 9) / kcal_1) * 100,
         sfat_energy_2 = ((sat_fat_2 * 9) / kcal_2) * 100,
         
         pf_seafood_1 = sum(DR1T_PF_SEAFD_HI, DR1T_PF_SEAFD_LOW),
         pf_seafood_2 = sum(DR2T_PF_SEAFD_HI, DR2T_PF_SEAFD_LOW),
         
         # includes legumes and soy foods
         leg_tot_1 = sum(pf_leg_1, pf_soy_1),
         leg_tot_2 = sum(pf_leg_2, pf_soy_2),
         
         pf_animal_1 = sum(pf_egg_1, pf_redm_tot_1, pf_poultry_tot_1, pf_seafood_1),
         pf_animal_2 = sum(pf_egg_2, pf_redm_tot_2, pf_poultry_tot_2, pf_seafood_2),
         
         pf_plant_1 = sum(pf_leg_1, pf_ns_1, pf_soy_1),
         pf_plant_2 = sum(pf_leg_2, pf_ns_2, pf_soy_2),
         
         # added
         veg_tot_1 = sum(veg_dg_1, veg_ro_1, veg_oth_1, veg_sta_1),
         veg_tot_2 = sum(veg_dg_2, veg_ro_2, veg_oth_2, veg_sta_2),
         
         gr_tot_1 = sum(gr_whole_1, gr_refined_1),
         gr_tot_2 = sum(gr_whole_2, gr_refined_2),
         
         pf_tot_1 = sum(pf_animal_1, pf_plant_1),
         pf_tot_2 = sum(pf_animal_2, pf_plant_2),
         
         # added sugar as grams
         added_sugar_grams_1 = added_sugar_1 * 4.2,
         added_sugar_grams_2 = added_sugar_2 * 4.2,
         
         afs_tot_1 = sum(oil_1, sat_fat_1, added_sugar_grams_1),
         afs_tot_2 = sum(oil_2, sat_fat_2, added_sugar_grams_2)
         
  )

# select the variables we need
nhanes_comb4 <- nhanes_comb3 %>% select(SEQN, RIAGENDR, RIDRETH1, DMDEDUC2,
                                        INDFMPIR, RIDAGEYR, SDMVPSU, SDMVSTRA,
                                        WTDRD1, WTDR2D, DR1DRSTZ, DR2DRSTZ, 
                                        DRDINT, ends_with("_1"), ends_with("_2")) %>% 
  ungroup() # stop using rowwise

# STEP 3: CREATE SUBGROUPS -----

nhanes_comb5 <- nhanes_comb4 %>% mutate(
  
  female = ifelse(RIAGENDR == 2, 1, 0),
  
  sex = ifelse(female == 1, 1, 2),
  
  race = recode(RIDRETH1,
                `3` = 1,
                `4` = 2,
                `1` = 3,
                `2` = 3,
                `5` = 4),
  
  age = case_when(RIDAGEYR >= 20 & RIDAGEYR < 35 ~ 1,
                  RIDAGEYR >= 35 & RIDAGEYR < 45 ~ 2,
                  RIDAGEYR >= 45 & RIDAGEYR < 55 ~ 3,
                  RIDAGEYR >= 55 & RIDAGEYR < 65 ~ 4,
                  RIDAGEYR >= 65 & RIDAGEYR < 75 ~ 5,
                  RIDAGEYR >= 75 ~ 6),
  
  # create new weight variable
  wtnew = WTDRD1/2)

# STEP 2c: CREATE AVERAGES OF DIETARY FACTORS -----

nhanes_comb6 <- nhanes_comb5 %>%
  rowwise() %>%
  mutate(kcal = mean(c(kcal_1, kcal_2), na.rm = TRUE),
         sat_fat = mean(c(sat_fat_1, sat_fat_2), na.rm = TRUE),
         sodium = mean(c(sodium_1, sodium_2), na.rm = TRUE),
         gr_refined = mean(c(gr_refined_1, gr_refined_2), na.rm = TRUE),
         gr_whole = mean(c(gr_whole_1, gr_whole_2), na.rm = TRUE),
         added_sugar = mean(c(added_sugar_1, added_sugar_2), na.rm = TRUE),
         fruit_tot = mean(c(fruit_tot_1, fruit_tot_2), na.rm = TRUE),
         fruit_exc_juice = mean(c(fruit_exc_juice_1, fruit_exc_juice_2), na.rm = TRUE),
         fruit_juice = mean(c(fruit_juice_1, fruit_juice_2), na.rm = TRUE),
         fiber = mean(c(fiber_1, fiber_2), na.rm = TRUE),
         dairy_tot = mean(c(dairy_tot_1, dairy_tot_2), na.rm = TRUE),
         dairy_cow = mean(c(dairy_cow_1, dairy_cow_2), na.rm = TRUE),
         dairy_soy = mean(c(dairy_soy_1, dairy_soy_2), na.rm = TRUE),
         veg_dg = mean(c(veg_dg_1, veg_dg_2), na.rm = TRUE),
         veg_oth = mean(c(veg_oth_1, veg_oth_2), na.rm = TRUE),
         veg_ro = mean(c(veg_ro_1, veg_ro_2), na.rm = TRUE),
         veg_sta = mean(c(veg_sta_1, veg_sta_2), na.rm = TRUE),
         veg_leg = mean(c(veg_leg_1, veg_leg_2), na.rm = TRUE),
         veg_exc_sta = mean(c(veg_exc_sta_1, veg_exc_sta_2), na.rm = TRUE),
         oil = mean(c(oil_1, oil_2), na.rm = TRUE),
         pf_egg = mean(c(pf_egg_1, pf_egg_2), na.rm = TRUE),
         pf_ns = mean(c(pf_ns_1, pf_ns_2), na.rm = TRUE),
         pf_soy = mean(c(pf_soy_1, pf_soy_2), na.rm = TRUE),
         pf_poultry = mean(c(pf_poultry_1, pf_poultry_2), na.rm = TRUE),
         pf_poultry_tot = mean(c(pf_poultry_tot_1, pf_poultry_tot_2), na.rm = TRUE),
         pf_pm = mean(c(pf_pm_1, pf_pm_2), na.rm = TRUE),
         pf_redm = mean(c(pf_redm_1, pf_redm_2), na.rm = TRUE),
         pf_redm_tot = mean(c(pf_redm_tot_1, pf_redm_tot_2), na.rm = TRUE),
         pf_organ = mean(c(pf_organ_1, pf_organ_2), na.rm = TRUE),
         pf_leg = mean(c(pf_leg_1, pf_leg_2), na.rm = TRUE),
         sea_omega3_fa = mean(c(sea_omega3_fa_1, sea_omega3_fa_2), na.rm = TRUE),
         pufa_energy = mean(c(pufa_energy_1, pufa_energy_2), na.rm = TRUE),
         sfat_energy = mean(c(sfat_energy_1, sfat_energy_2), na.rm = TRUE),
         pf_seafood = mean(c(pf_seafood_1, pf_seafood_2), na.rm = TRUE),
         leg_tot = mean(c(leg_tot_1, leg_tot_2), na.rm = TRUE),
         pf_animal = mean(c(pf_animal_1, pf_animal_2), na.rm = TRUE),
         pf_plant = mean(c(pf_plant_1, pf_plant_2), na.rm = TRUE),
         
         # added
         veg_tot = mean(c(veg_tot_1, veg_tot_2), na.rm = TRUE),
         gr_tot = mean(c(gr_tot_1, gr_tot_2), na.rm = TRUE),
         pf_tot = mean(c(pf_tot_1, pf_tot_2), na.rm = TRUE),
         afs_tot = mean(c(afs_tot_1, afs_tot_2), na.rm = TRUE))


# get rid of NaN
nhanes_comb6[nhanes_comb6 == "NaN"] <- NA

# ungroup
nhanes_comb7 <- nhanes_comb6 %>% ungroup()

# Merge with subgroup file
subgroups <- read_csv("in/ALL PILLARS/Dietary intake/raw data/population_subgroups_48_070723_FINAL.csv")

nhanes_comb8 <-
  nhanes_comb7 %>% 
  left_join(subgroups, by = c("age" = "Age", 
                              "sex" = "Sex", 
                              "race" = "Race"))

# create final dataset
nhanes_final <- nhanes_comb8

# look at meat variables
nhanes_final %>%
  select(SEQN, starts_with(c("pf_redm", "pf_poultry", "pf_pm", "pf_organ"))) %>%
  mutate(sumtot = (pf_redm + pf_poultry + pf_pm + pf_organ == pf_redm_tot + pf_poultry_tot),
         sum1 = (pf_redm_1 + pf_poultry_1 + pf_pm_1 + pf_organ_1 == pf_redm_tot_1 + pf_poultry_tot_1),
         sum2 = (pf_redm_2 + pf_poultry_2 + pf_pm_2 + pf_organ_2 == pf_redm_tot_2 + pf_poultry_tot_2)) %>%
  View()

nhanes_final %>%
  select(SEQN, starts_with(c("pf_redm", "pf_poultry", "pf_pm", "pf_organ"))) %>%
  mutate(sum1 = (pf_redm + pf_poultry + pf_pm + pf_organ == pf_redm_tot + pf_poultry_tot)) %>%
  filter(sum1 == "FALSE") %>%
  View()

# look at day 1
nhanes_final %>%
  rowwise() %>%
  select(SEQN, pf_redm_1, pf_poultry_1, pf_pm_1, pf_organ_1, pf_redm_tot_1, pf_poultry_tot_1) %>%
  mutate(sum1 = round(sum(pf_redm_1, pf_poultry_1, pf_pm_1, pf_organ_1), digits = 3),
         sum2 = round(sum(pf_redm_tot_1, pf_poultry_tot_1), digits = 3),
         my_test = (sum1 == sum2)) %>%
  filter(my_test == "FALSE") %>%
  mutate(my_subtract = sum2 - sum1) %>%
  filter(my_subtract < -0.05 | my_subtract > 0.05) %>%
  View() # not bad

# look at day2
nhanes_final %>%
  rowwise() %>%
  select(SEQN, pf_redm_2, pf_poultry_2, pf_pm_2, pf_organ_2, pf_redm_tot_2, pf_poultry_tot_2) %>%
  mutate(sum1 = round(sum(pf_redm_2, pf_poultry_2, pf_pm_2, pf_organ_2), digits = 3),
         sum2 = round(sum(pf_redm_tot_2, pf_poultry_tot_2), digits = 3),
         my_test = (sum1 == sum2)) %>%
  filter(my_test == "FALSE") %>%
  mutate(my_subtract = sum2 - sum1) %>%
  filter(my_subtract < -0.05 | my_subtract > 0.05) %>%
  View() # not bad

# LOOK AT ORGAN MEATS
# organ_day1 <- foods_day1_2 %>% 
#   filter(DR1I_PF_ORGAN > 0) %>% 
#   select(DESCRIPTION) %>% 
#   distinct()
# 
# organ_day2 <- foods_day2_2 %>% 
#   filter(DR2I_PF_ORGAN > 0) %>% 
#   select(DESCRIPTION) %>% 
#   distinct()
# 
# organ_bothdays <- rbind(organ_day1, organ_day2) %>% distinct() %>% arrange(DESCRIPTION)

#export
# write_csv(organ_bothdays, "in/ALL PILLARS/Dietary intake/processed meat/organ_meats_bothdays.csv")

# import updated mapping here
# new_organ <- read_csv("in/ALL PILLARS/Dietary intake/processed meat/organ_meats_bothdays_mapped_121323.csv")


# STEP 2d: EXAMINE NHANES DATA -----

# check missing
summary(nhanes_final)

# check for outliers

# kcal < 500
nhanes_final %>% filter(kcal_1 < 500) %>% nrow()  #233
nhanes_final %>% filter(kcal_2 < 500) %>% nrow()  #301

# kcal > 3500
nhanes_final %>% filter(kcal_1 > 3500) %>% nrow()  #1028
nhanes_final %>% filter(kcal_2 > 3500) %>% nrow()  #588

# do not remove because I will filter out 
# dietary recalls that are not valid later

# diet recall status
table(nhanes_final$DR1DRSTZ, useNA = "always") 
table(nhanes_final$DR2DRSTZ, useNA = "always") 

# first, create inAnalysis variable
nhanes_final1 <- nhanes_final %>% 
  rowwise() %>% 
  mutate(
    # Define sub-population of interest: 
    # Adults aged 20+ with 1 or 2 days of reliable dietary recalls
    
    reliable_yes = ifelse((DRDINT == 1 & DR1DRSTZ == 1) | (DRDINT == 2 & DR1DRSTZ == 1 & DR2DRSTZ == 1), 1, 0),
    
    inAnalysis = (!(is.na(subgroup)) & reliable_yes == 1), # if subgroup ISN'T missing and reliable data
    
    # Change NAs to 0s, otherwise svydesign function below won't run
    wtnew = ifelse(is.na(wtnew), 0, wtnew),
    SDMVPSU = ifelse(is.na(SDMVPSU), 0, SDMVPSU),
    SDMVSTRA = ifelse(is.na(SDMVSTRA), 0, SDMVSTRA)
  )

# check new survey weight
nhanes_final1 %>% select(SEQN, wtnew, SDMVPSU, SDMVSTRA, inAnalysis) %>% View() # looks good

# export
write_rds(nhanes_final1,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_clean.rds")



