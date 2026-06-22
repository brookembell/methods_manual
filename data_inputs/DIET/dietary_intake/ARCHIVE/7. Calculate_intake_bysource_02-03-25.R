# Calculate intake of dietary factors, by food source, using NHANES 2015-2018 datasets
# Author: Brooke Bell
# Date: 02-03-25

# SET-UP -----

rm(list=ls())

# load packages
library(foreign)
library(survey)
library(tidyverse)
library(psych)
library(haven)

export_date <- "02-03-2025"

# IMPORT NHANES DATASETS -----

# create day 1 and 2 datasets
foods_day1 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day1_clean.rds")

foods_day2 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day2_clean.rds")

# import SSB datasets
ssb_day1 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day1_ssb.rds")

ssb_day2 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day2_ssb.rds")

ssb_day1 %>% filter(is.na(ssb))
ssb_day2 %>% filter(is.na(ssb))

foods_day1 %>% filter(is.na(DR1I_F_CITMLB)) %>% View()
foods_day1 %>% filter(DR1DRSTZ == 1) %>% View()

# add ssb variable to foods datasets

foods_day1_ <- left_join(foods_day1, ssb_day1, 
                         by = c("SEQN", "DR1ILINE", "DR1IFDCD", "DESCRIPTION", "DR1IGRMS")) %>% 
  rename(ssb_yes = ssb) %>% 
  mutate(ssb = ifelse(ssb_yes == 1, DR1IGRMS, NA),
         ssb = ifelse(ssb_yes == 0 & DR1DRSTZ == 1, 0, ssb)) %>% 
  relocate(ssb_yes, ssb, .after = "DESCRIPTION")

# foods_day1_ %>% filter(is.na(ssb)) %>% View()

foods_day2_ <- left_join(foods_day2, ssb_day2, 
                         by = c("SEQN", "DR2ILINE", "DR2IFDCD", "DESCRIPTION", "DR2IGRMS")) %>% 
  rename(ssb_yes = ssb) %>% 
  mutate(ssb = ifelse(ssb_yes == 1, DR2IGRMS, NA),
         ssb = ifelse(ssb_yes == 0 & DR2DRSTZ == 1, 0, ssb)) %>% 
  relocate(ssb_yes, ssb, .after = "DESCRIPTION")

# Calculate amount of intake for each dietary factor
# for day 1 and day 2
# by SEQN and foodsource

foods_day1_bysource <- foods_day1_ %>% 
  group_by(SEQN, foodsource) %>% 
  summarise(sat_fat = sum(sat_fat),
            p_fat = sum(p_fat),
            sodium = sum(sodium),
            ssb = sum(ssb),
            gr_refined = sum(gr_refined),
            gr_whole = sum(gr_whole),
            added_sugar = sum(added_sugar),
            fruit_tot = sum(fruit_tot),
            fruit_exc_juice = sum(fruit_exc_juice),
            fruit_juice = sum(fruit_juice),
            fiber = sum(fiber),
            dairy_tot = sum(dairy_tot),
            dairy_cow = sum(dairy_cow),
            dairy_soy = sum(dairy_soy),
            veg_dg = sum(veg_dg),
            veg_oth = sum(veg_oth),
            veg_ro = sum(veg_ro),
            veg_sta = sum(veg_sta),
            veg_leg = sum(veg_leg),
            veg_exc_sta = sum(veg_exc_sta),
            oil = sum(oil),
            pf_egg = sum(pf_egg),
            pf_ns = sum(pf_ns),
            pf_soy = sum(pf_soy),
            pf_poultry = sum(pf_poultry),
            pf_poultry_tot = sum(pf_poultry_tot),
            pf_redm = sum(pf_redm),
            pf_redm_tot = sum(pf_redm_tot),
            pf_leg = sum(pf_leg),
            pf_pm = sum(pf_pm),
            pf_seafood = sum(pf_seafood),
            leg_tot = sum(leg_tot),
            pf_animal = sum(pf_animal),
            pf_plant = sum(pf_plant),
            kcal = sum(kcal),
            sea_omega3_fa = sum(sea_omega3_fa)) %>% 
  mutate(day = 1,
         ssb = ifelse(!(is.na(kcal)) & is.na(ssb), 0, ssb))

# foods_day1_bysource %>% filter(is.na(ssb)) %>% select(SEQN, foodsource, ssb, kcal) %>%  View()

foods_day2_bysource <- foods_day2_ %>% 
  group_by(SEQN, foodsource) %>% 
  summarise(sat_fat = sum(sat_fat),
            p_fat = sum(p_fat),
            sodium = sum(sodium),
            ssb = sum(ssb),
            gr_refined = sum(gr_refined),
            gr_whole = sum(gr_whole),
            added_sugar = sum(added_sugar),
            fruit_tot = sum(fruit_tot),
            fruit_exc_juice = sum(fruit_exc_juice),
            fruit_juice = sum(fruit_juice),
            fiber = sum(fiber),
            dairy_tot = sum(dairy_tot),
            dairy_cow = sum(dairy_cow),
            dairy_soy = sum(dairy_soy),
            veg_dg = sum(veg_dg),
            veg_oth = sum(veg_oth),
            veg_ro = sum(veg_ro),
            veg_sta = sum(veg_sta),
            veg_leg = sum(veg_leg),
            veg_exc_sta = sum(veg_exc_sta),
            oil = sum(oil),
            pf_egg = sum(pf_egg),
            pf_ns = sum(pf_ns),
            pf_soy = sum(pf_soy),
            pf_poultry = sum(pf_poultry),
            pf_poultry_tot = sum(pf_poultry_tot),
            pf_redm = sum(pf_redm),
            pf_redm_tot = sum(pf_redm_tot),
            pf_leg = sum(pf_leg),
            pf_pm = sum(pf_pm),
            pf_seafood = sum(pf_seafood),
            leg_tot = sum(leg_tot),
            pf_animal = sum(pf_animal),
            pf_plant = sum(pf_plant),
            kcal = sum(kcal),
            sea_omega3_fa = sum(sea_omega3_fa)) %>% 
  mutate(day = 2,
         ssb = ifelse(!(is.na(kcal)) & is.na(ssb), 0, ssb))

foods_day2_bysource %>% filter(is.na(ssb)) %>% select(SEQN, foodsource, ssb, kcal) %>%  View()

# create total now

# foods_day1_total <- foods_day1 %>% 
#   group_by(SEQN) %>% 
#   summarise(gr_refined = sum(gr_refined),
#             gr_whole = sum(gr_whole),
#             added_sugar = sum(added_sugar),
#             fruit = sum(fruit),
#             fruit_juice = sum(fruit_juice),
#             fiber = sum(fiber),
#             dairy = sum(dairy),
#             veg_dg = sum(veg_dg),
#             veg_oth = sum(veg_oth),
#             veg_ro = sum(veg_ro),
#             veg_sta = sum(veg_sta),
#             veg_leg = sum(veg_leg),
#             oil = sum(oil),
#             pf_egg = sum(pf_egg),
#             pf_ns = sum(pf_ns),
#             pf_soy = sum(pf_soy),
#             pf_poultry = sum(pf_poultry),
#             pf_redm = sum(pf_redm),
#             pf_pm = sum(pf_pm),
#             pf_leg = sum(pf_leg),
#             veg_exc_sta = sum(veg_exc_sta),
#             fruit_exc_juice = sum(fruit_exc_juice),
#             pf_seafood = sum(pf_seafood),
#             leg_tot = sum(leg_tot),
#             sat_fat = sum(sat_fat),
#             p_fat = sum(p_fat),
#             sodium = sum(sodium),
#             sea_omega3_fa = sum(sea_omega3_fa),
#             pf_animal = sum(pf_animal),
#             pf_plant = sum(pf_plant),
#             kcal = sum(kcal)) %>% 
#   mutate(day = 1,
#          foodsource = "Total")

# na.rm =TRUE

foods_day1_total <- foods_day1_ %>% 
  group_by(SEQN) %>% 
  summarise(gr_refined = sum(gr_refined, na.rm = TRUE),
            gr_whole = sum(gr_whole, na.rm = TRUE),
            added_sugar = sum(added_sugar, na.rm = TRUE),
            fruit_tot = sum(fruit_tot, na.rm = TRUE),
            fruit_exc_juice = sum(fruit_exc_juice, na.rm = TRUE),
            fruit_juice = sum(fruit_juice, na.rm = TRUE),
            fiber = sum(fiber, na.rm = TRUE),
            dairy_tot = sum(dairy_tot, na.rm = TRUE),
            dairy_cow = sum(dairy_cow, na.rm = TRUE),
            dairy_soy = sum(dairy_soy, na.rm = TRUE),
            veg_dg = sum(veg_dg, na.rm = TRUE),
            veg_oth = sum(veg_oth, na.rm = TRUE),
            veg_ro = sum(veg_ro, na.rm = TRUE),
            veg_sta = sum(veg_sta, na.rm = TRUE),
            veg_leg = sum(veg_leg, na.rm = TRUE),
            veg_exc_sta = sum(veg_exc_sta, na.rm = TRUE),
            oil = sum(oil, na.rm = TRUE),
            pf_egg = sum(pf_egg, na.rm = TRUE),
            pf_ns = sum(pf_ns, na.rm = TRUE),
            pf_soy = sum(pf_soy, na.rm = TRUE),
            pf_poultry = sum(pf_poultry, na.rm = TRUE),
            pf_poultry_tot = sum(pf_poultry_tot, na.rm = TRUE),
            pf_redm = sum(pf_redm, na.rm = TRUE),
            pf_redm_tot = sum(pf_redm_tot, na.rm = TRUE),
            pf_pm = sum(pf_pm, na.rm = TRUE),
            pf_leg = sum(pf_leg, na.rm = TRUE),
            pf_seafood = sum(pf_seafood, na.rm = TRUE),
            leg_tot = sum(leg_tot, na.rm = TRUE),
            sat_fat = sum(sat_fat, na.rm = TRUE),
            p_fat = sum(p_fat, na.rm = TRUE),
            ssb = sum(ssb, na.rm = TRUE),
            sodium = sum(sodium, na.rm = TRUE),
            sea_omega3_fa = sum(sea_omega3_fa, na.rm = TRUE),
            pf_animal = sum(pf_animal, na.rm = TRUE),
            pf_plant = sum(pf_plant, na.rm = TRUE),
            kcal = sum(kcal, na.rm = TRUE)) %>% 
  mutate(day = 1,
         foodsource = "Total")


# foods_day2_total <- foods_day2 %>% 
#   group_by(SEQN) %>% 
#   summarise(sat_fat = sum(sat_fat),
#             p_fat = sum(p_fat),
#             sodium = sum(sodium),
#             sea_omega3_fa = sum(sea_omega3_fa),
#             gr_refined = sum(gr_refined),
#             gr_whole = sum(gr_whole),
#             added_sugar = sum(added_sugar),
#             fruit = sum(fruit),
#             fruit_juice = sum(fruit_juice),
#             fiber = sum(fiber),
#             dairy = sum(dairy),
#             veg_dg = sum(veg_dg),
#             veg_oth = sum(veg_oth),
#             veg_ro = sum(veg_ro),
#             veg_sta = sum(veg_sta),
#             veg_leg = sum(veg_leg),
#             oil = sum(oil),
#             pf_egg = sum(pf_egg),
#             pf_ns = sum(pf_ns),
#             pf_soy = sum(pf_soy),
#             pf_poultry = sum(pf_poultry),
#             pf_redm = sum(pf_redm),
#             pf_pm = sum(pf_pm),
#             pf_leg = sum(pf_leg),
#             veg_exc_sta = sum(veg_exc_sta),
#             fruit_exc_juice = sum(fruit_exc_juice),
#             pf_seafood = sum(pf_seafood),
#             leg_tot = sum(leg_tot),
#             pf_animal = sum(pf_animal),
#             pf_plant = sum(pf_plant),
#             kcal = sum(kcal)) %>% 
#   mutate(day = 2,
#          foodsource = "Total")

# na.rm = TRUE
foods_day2_total <- foods_day2_ %>% 
  group_by(SEQN) %>% 
  summarise(gr_refined = sum(gr_refined, na.rm = TRUE),
            gr_whole = sum(gr_whole, na.rm = TRUE),
            added_sugar = sum(added_sugar, na.rm = TRUE),
            fruit_tot = sum(fruit_tot, na.rm = TRUE),
            fruit_exc_juice = sum(fruit_exc_juice, na.rm = TRUE),
            fruit_juice = sum(fruit_juice, na.rm = TRUE),
            fiber = sum(fiber, na.rm = TRUE),
            dairy_tot = sum(dairy_tot, na.rm = TRUE),
            dairy_cow = sum(dairy_cow, na.rm = TRUE),
            dairy_soy = sum(dairy_soy, na.rm = TRUE),
            veg_dg = sum(veg_dg, na.rm = TRUE),
            veg_oth = sum(veg_oth, na.rm = TRUE),
            veg_ro = sum(veg_ro, na.rm = TRUE),
            veg_sta = sum(veg_sta, na.rm = TRUE),
            veg_leg = sum(veg_leg, na.rm = TRUE),
            veg_exc_sta = sum(veg_exc_sta, na.rm = TRUE),
            oil = sum(oil, na.rm = TRUE),
            pf_egg = sum(pf_egg, na.rm = TRUE),
            pf_ns = sum(pf_ns, na.rm = TRUE),
            pf_soy = sum(pf_soy, na.rm = TRUE),
            pf_poultry = sum(pf_poultry, na.rm = TRUE),
            pf_poultry_tot = sum(pf_poultry_tot, na.rm = TRUE),
            pf_redm = sum(pf_redm, na.rm = TRUE),
            pf_redm_tot = sum(pf_redm_tot, na.rm = TRUE),
            pf_pm = sum(pf_pm, na.rm = TRUE),
            pf_leg = sum(pf_leg, na.rm = TRUE),
            pf_seafood = sum(pf_seafood, na.rm = TRUE),
            leg_tot = sum(leg_tot, na.rm = TRUE),
            sat_fat = sum(sat_fat, na.rm = TRUE),
            p_fat = sum(p_fat, na.rm = TRUE),
            ssb = sum(ssb, na.rm = TRUE),
            sodium = sum(sodium, na.rm = TRUE),
            sea_omega3_fa = sum(sea_omega3_fa, na.rm = TRUE),
            pf_animal = sum(pf_animal, na.rm = TRUE),
            pf_plant = sum(pf_plant, na.rm = TRUE),
            kcal = sum(kcal, na.rm = TRUE)) %>% 
  mutate(day = 2,
         foodsource = "Total")

foods_day1_total %>% filter(SEQN == 83765) %>% View()
foods_day2_total %>% filter(SEQN == 83765) %>% View()
foods_day1 %>% filter(SEQN == 83765) %>% View() # breastmilk


foods_day1_comb <- rbind(foods_day1_bysource, foods_day1_total) %>% arrange(SEQN)

foods_day2_comb <- rbind(foods_day2_bysource, foods_day2_total) %>% arrange(SEQN)

foods_join <- rbind(foods_day1_comb, foods_day2_comb) %>% arrange(SEQN, day, foodsource)

foods_join %>% filter(SEQN == "83762") %>% View()

# create template dataset to join with

ids <- foods_day1_ %>% select(SEQN) %>% distinct()

ids_gro <- ids %>% mutate(foodsource = "Grocery")
ids_oth <- ids %>% mutate(foodsource = "Other")
ids_tot <- ids %>% mutate(foodsource = "Total")
ids_day1 <- ids %>% mutate(day=1)
ids_day2 <- ids %>% mutate(day=2)

ids_join_pt1 <- full_join(ids_gro, ids_oth) %>% 
  full_join(ids_tot) %>% 
  arrange(SEQN)

ids_join_pt2 <- full_join(ids_day1, ids_day2) %>% 
  arrange(SEQN)

ids_join <- full_join(ids_join_pt1, ids_join_pt2)

foods_tot <- left_join(ids_join, foods_join) %>% 
  arrange(SEQN, day, foodsource)
  #replace(is.na(.), 0)

# look at those with missing values
foods_tot %>% filter(is.na(sat_fat)) %>% View()
foods_tot %>% filter(sat_fat == 0) %>% View()

foods_tot1 <- foods_tot %>% 
  group_by(SEQN, day) %>% 
  mutate(foo1 = sum(sat_fat, na.rm = TRUE),
         foo2 = sum(sodium, na.rm = TRUE),
         foo3 = sum(kcal, na.rm = TRUE)) %>% 
  ungroup()

foods_tot1 %>% filter(is.na(sat_fat) & foo1 > 0) %>% View()

foods_tot1 %>% filter(SEQN == 83738) %>% View()

# make sure there are no Totals
foods_tot1 %>% filter(is.na(sat_fat) & foo1 > 0) %>% select(foodsource) %>% table() #good

# okay if foo > 1, then assign 0 to missing values
# temp_dat <- foods_tot1 %>% filter(is.na(sat_fat) & foo1 > 0)
temp_dat <- foods_tot1 %>% filter((is.na(sat_fat) & foo1 > 0) | (is.na(sodium) & foo2 > 0) | (is.na(kcal) & foo3 > 0))

temp_dat[is.na(temp_dat)] <- 0

# row patch this dataset with foods_tot1
foods_tot2 <- rows_patch(foods_tot1, temp_dat, by = c("SEQN", "foodsource", "day"))

# check again
foods_tot2 %>% filter(is.na(sat_fat) & foo1 > 0) #good

foods_tot2 %>% filter(foodsource == "Total" & kcal == 0 & sodium == 0 & sat_fat == 0) %>% View()

foods_tot2 %>% filter(SEQN == "87601") %>% View()

foods_tot2 %>% filter(SEQN == 83765) %>% View()

# temp_dat_new <- 
#   foods_tot2 %>% 
#   filter(foodsource == "Total" & kcal == 0 & sodium == 0 & sat_fat == 0)
# 
# temp_dat_new[temp_dat_new == 0] <- NA

# row update this dataset with foods_tot2
# foods_tot3 <- rows_update(foods_tot2, temp_dat_new, by = c("SEQN", "foodsource", "day"))

# foods_tot3 %>% filter(SEQN == "83840") %>% View()

# foods_day1 %>% filter(SEQN == "83840") %>% View() #breast milk 

# okay at this level, calculate pufa

foods_tot3 <- foods_tot2 %>% 
  
                     mutate(pufa_energy = ((p_fat * 9) / kcal) * 100, # honestly not sure if this is best place to do this
                     sfat_energy = ((sat_fat * 9) / kcal) * 100,
                     
                     pufa_energy = ifelse(pufa_energy == "NaN", 0, pufa_energy),
                     sfat_energy = ifelse(sfat_energy == "NaN", 0, sfat_energy))

# calculate average food intake for each dietary factor (averaging day 1 and day 2)
foods_bysource <- foods_tot3 %>% 
  group_by(SEQN, foodsource) %>% 
  summarise(sat_fat = mean(sat_fat, na.rm = TRUE),
            p_fat = mean(p_fat, na.rm = TRUE),
            sodium = mean(sodium, na.rm = TRUE),
            ssb = mean(ssb, na.rm = TRUE),
            gr_refined = mean(gr_refined, na.rm = TRUE),
            gr_whole = mean(gr_whole, na.rm = TRUE),
            added_sugar = mean(added_sugar, na.rm = TRUE),
            fruit_tot = mean(fruit_tot, na.rm = TRUE),
            fruit_exc_juice = mean(fruit_exc_juice, na.rm = TRUE),
            fruit_juice = mean(fruit_juice, na.rm = TRUE),
            fiber = mean(fiber, na.rm = TRUE),
            dairy_tot = mean(dairy_tot, na.rm = TRUE),
            dairy_cow = mean(dairy_cow, na.rm = TRUE),
            dairy_soy = mean(dairy_soy, na.rm = TRUE),
            veg_dg = mean(veg_dg, na.rm = TRUE),
            veg_oth = mean(veg_oth, na.rm = TRUE),
            veg_ro = mean(veg_ro, na.rm = TRUE),
            veg_sta = mean(veg_sta, na.rm = TRUE),
            veg_leg = mean(veg_leg, na.rm = TRUE),
            veg_exc_sta = mean(veg_exc_sta, na.rm = TRUE),
            oil = mean(oil, na.rm = TRUE),
            pf_egg = mean(pf_egg, na.rm = TRUE),
            pf_ns = mean(pf_ns, na.rm = TRUE),
            pf_soy = mean(pf_soy, na.rm = TRUE),
            pf_poultry = mean(pf_poultry, na.rm = TRUE),
            pf_poultry_tot = mean(pf_poultry_tot, na.rm = TRUE),
            pf_redm = mean(pf_redm, na.rm = TRUE),
            pf_redm_tot = mean(pf_redm_tot, na.rm = TRUE),
            pf_pm = mean(pf_pm, na.rm = TRUE),
            pf_leg = mean(pf_leg, na.rm = TRUE),
            pf_seafood = mean(pf_seafood, na.rm = TRUE),
            leg_tot = mean(leg_tot, na.rm = TRUE),
            pf_animal = mean(pf_animal, na.rm = TRUE),
            pf_plant = mean(pf_plant, na.rm = TRUE),
            kcal = mean(kcal, na.rm = TRUE),
            sfat_energy = mean(sfat_energy, na.rm = TRUE), 
            pufa_energy = mean(pufa_energy, na.rm = TRUE),
            sea_omega3_fa = mean(sea_omega3_fa, na.rm = TRUE))

foods_bysource %>% filter(SEQN == 83765) %>% View()

# import subgroup-seqn mapping
nhanes <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_wide.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

# join
foods_bysource1 <- left_join(foods_bysource, subgroup_dat, by = "SEQN")

# is there anybody who not in analysis but has a subgroup? no, good
foods_bysource1 %>% filter(!is.na(subgroup) & inAnalysis == FALSE)

# change NaN to NA
foods_bysource1[foods_bysource1 == "NaN"] <- NA

foods_bysource1 %>% filter(SEQN == 83765) %>% View()

foods_day1 %>% filter(SEQN == "83765") %>% View() #baby
foods_day1 %>% filter(SEQN == "83939") %>% View()

foods_bysource1 %>% filter(inAnalysis == "TRUE" & is.na(fruit_tot)) %>% View()

# create two datasets: grocery_dat and other_dat

grocery_dat <- foods_bysource1 %>% filter(foodsource == "Grocery") %>% ungroup()
other_dat <- foods_bysource1 %>% filter(foodsource == "Other") %>% ungroup()
total_dat <- foods_bysource1 %>% filter(foodsource == "Total") %>% ungroup()


# CALCULATE MEANS -----

# Define survey design for GROCERY dataset 
my_svy_grocery <- svydesign(data=grocery_dat, 
                          id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                          strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                          weights=~wtnew, # New sample weight
                          nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_grocery_sub <- subset(my_svy_grocery, inAnalysis==1) 

# Define survey design for OTHER dataset 
my_svy_other <- svydesign(data=other_dat, 
                            id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                            strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                            weights=~wtnew, # New sample weight
                            nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_other_sub <- subset(my_svy_other, inAnalysis==1) 

# Define survey design for TOTAL dataset 
my_svy_total <- svydesign(data=total_dat, 
                          id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                          strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                          weights=~wtnew, # New sample weight
                          nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_total_sub <- subset(my_svy_total, inAnalysis==1) 


## CAlCULATE ##

# create diet vars vec
diet_vars <- c("gr_refined", "gr_whole", "dairy_tot", "dairy_cow", "dairy_soy", "fruit_tot", "fruit_exc_juice", "fruit_juice", 
               "veg_exc_sta", "veg_dg", "veg_oth", "veg_ro", "veg_sta", "veg_leg", "pf_ns", "pf_soy", "pf_leg",
               "pf_egg", "pf_poultry", "pf_poultry_tot", "pf_redm", "pf_redm_tot", "pf_pm", "pf_seafood", "leg_tot", "added_sugar", "ssb",
               "oil", "kcal", "sat_fat", "sodium", "fiber", "sea_omega3_fa", "pufa_energy", "sfat_energy",
               "pf_animal", "pf_plant")

# Calculate mean intake of grocery foods, by subgroup
grocery_bysub <- svyby(reformulate(diet_vars), 
      ~subgroup, 
      my_svy_grocery_sub, 
      svymean)

# remove se vars
grocery_bysub1 <- grocery_bysub %>% select(-c(starts_with("se.")))

# pivot longer
grocery_bysub_long <-
  pivot_longer(grocery_bysub1,
             cols = !subgroup,
             names_to = "food",
             values_to = "mean_intake_grocery")

# Calculate mean intake of other foods, by subgroup
other_bysub <- svyby(reformulate(diet_vars), 
      ~subgroup, 
      my_svy_other_sub, 
      svymean)

# remove se vars
other_bysub1 <- other_bysub %>% select(-c(starts_with("se.")))

# pivot longer
other_bysub_long <-
  pivot_longer(other_bysub1,
               cols = !subgroup,
               names_to = "food",
               values_to = "mean_intake_other")

# Calculate mean intake of TOTAL foods, by subgroup
total_bysub <- svyby(reformulate(diet_vars),
                     ~subgroup, 
                     my_svy_total_sub, 
                     svymean)

# remove se vars
total_bysub1 <- total_bysub %>% select(-c(starts_with("se.")))

# pivot longer
total_bysub_long <-
  pivot_longer(total_bysub1,
               cols = !subgroup,
               names_to = "food",
               values_to = "mean_intake_total")


# join
comb <- 
  left_join(grocery_bysub_long, other_bysub_long, by = c("subgroup", "food")) %>% 
  left_join(total_bysub_long, by = c("subgroup", "food"))

# calculate pro_gro variable

comb1 <-
  comb %>% 
  rowwise() %>% 
  mutate(pro_gro = mean_intake_grocery / mean_intake_total)

# look at infinity values
comb1 %>% filter(mean_intake_grocery == "Inf" | mean_intake_other == "Inf") %>% View()


# read in adj nhanes intake by subgroup
adj_intake <- 
  read_csv("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_bysub_02-03-2025.csv")

adj_intake1 <- adj_intake %>% mutate(food = str_remove(food, "_adj"))


# merge
pro_gro_dat <- left_join(comb1, adj_intake1, by = c("subgroup", "food")) %>% 
  relocate(mean, .after = mean_intake_total)

# how big is the difference between mean and mean_intake_total?

pro_gro_dat1 <- pro_gro_dat %>% mutate(perc = ((mean - mean_intake_total)/mean_intake_total) * 100,
                       perc = round(perc, 2)) 

# it's not too bad

# only keep needed vars

pro_gro_dat2 <- pro_gro_dat1 %>% select(!c(starts_with("mean_intake_"), perc)) %>% 
  relocate(SE, .after = mean)

pro_gro_dat3 <- pro_gro_dat2 %>% 
                 mutate(gro_mean_intake = mean * pro_gro,
                        gro_se_intake = SE * pro_gro,
                        oth_mean_intake = mean * (1-pro_gro),
                        oth_se_intake = SE * (1-pro_gro)) %>% 
  arrange(subgroup) %>% 
  relocate(c(food_label, food_desc), .after = last_col())

# export data

write_csv(pro_gro_dat3, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_bysub_bysource_", export_date, ".csv"))

pro_gro_dat3 %>% filter(food == "pf_poultry_tot")
