# Calculate intake of dietary factors using NHANES 2015-2018 datasets
# Unadjusted and adjusted
# Author: Brooke Bell
# Date: 02-03-25

# STEP 0: SET-UP -----

rm(list=ls())

# load packages
library(tidyverse)
library(survey)

export_date <- "02-03-2025"

# STEP 1: IMPORT NHANES DATASETS -----

nhanes_unadj <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_incl_ssb_clean.rds")
nhanes_adj <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_wide.rds")

# create diet vars vec
diet_vars <- c("gr_tot", "gr_refined", "gr_whole", 
               "dairy_tot", "dairy_cow", "dairy_soy",
               "fruit_tot", "fruit_exc_juice", "fruit_juice", 
               "veg_tot", "veg_exc_sta", "veg_dg", "veg_oth", "veg_ro", "veg_sta", "veg_leg", 
               "leg_tot", "pf_soy", "pf_leg", "pf_ns", 
               "pf_tot", "pf_egg", "pf_redm", "pf_redm_tot", "pf_poultry", "pf_poultry_tot", "pf_seafood", "pf_pm", 
               "pf_animal", "pf_plant",
               "afs_tot", "oil", "sat_fat", "added_sugar", 
               "ssb", "sodium", "fiber", 
               "sea_omega3_fa", "pufa_energy", "sfat_energy",
               "kcal")

diet_vars_adj <- c(paste0(diet_vars[!(diet_vars %in% c("kcal"))], "_adj"))

# STEP 2: CALCULATE MEAN/SE (UNADJUSTED) -----

# Define survey design for overall dataset 
my_svy_unadj <- svydesign(data=nhanes_unadj, 
                        id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                        strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                        weights=~wtnew, # New sample weight
                        nest=TRUE)

# Create a survey design object for the subset of interest 
# Subsetting the original survey design object ensures we keep the 
# design information about the number of clusters and strata
my_svy_unadj_sub <- subset(my_svy_unadj, inAnalysis==1) # unadjusted

# 1. To estimate the mean consumption among US adults 
# aged 20+ years who participated in the 2015-2018 cycles of NHANES. 
# Include means and standard errors.

# test out
svymean(~dairy_tot, my_svy_unadj_sub, na.rm = TRUE)

# test out dietary factors
svymean(~dairy_tot+pf_soy, my_svy_unadj_sub, na.rm = TRUE)

# test with subgroups
svyby(~dairy_tot, ~subgroup, my_svy_unadj_sub, svymean)

# test with subgroups & dietary factors
svyby(~dairy_tot+pf_soy, ~subgroup, my_svy_unadj_sub, svymean)

# CALCULATE: All foods

allfoods_unadj <- svymean(reformulate(diet_vars),
                    design = my_svy_unadj_sub,
                    na.rm = TRUE) %>% as.data.frame()

# add food column
allfoods_unadj1 <- rownames_to_column(allfoods_unadj, "food")

# CALCULATE: All foods by subgroup

allfoods_unadj_bysub <- svyby(reformulate(diet_vars),
                        ~subgroup, 
                        my_svy_unadj_sub, 
                        svymean)

# Reformat unadjusted output to match model data
my_se_unadj <- allfoods_unadj_bysub %>% select(subgroup, starts_with("se."))

my_mean_unadj <- allfoods_unadj_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_unadj_long <- my_se_unadj %>% pivot_longer(cols = starts_with("se."),
                                     names_to = "food",
                                     names_prefix = "se.",
                                     values_to = "SE")

my_mean_unadj_long <- my_mean_unadj %>% pivot_longer(cols = !subgroup,
                                         names_to = "food",
                                         values_to = "mean")

# combine
allfoods_unadj_bysub_long <- left_join(my_mean_unadj_long, my_se_unadj_long, by = c("subgroup", "food"))

# Merge with diet factor description dataset

# read in diet factor dataset
diet_dat <- read_csv("in/ALL PILLARS/Dietary intake/raw data/dietary_factors_010424_FINAL.csv")

# join
allfoods_unadj2 <- left_join(allfoods_unadj1, diet_dat, by = c("food" = "Food_group")) %>% 
  rename(food_label = Var_label,
         food_desc = Var_desc)

allfoods_unadj_bysub_long1 <- left_join(allfoods_unadj_bysub_long, diet_dat, by = c("food" = "Food_group")) %>% 
  rename(food_label = Var_label,
         food_desc = Var_desc)

# export
write_csv(allfoods_unadj2, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_unadj_", export_date, ".csv"))

write_csv(allfoods_unadj_bysub_long1, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_unadj_bysub_", export_date, ".csv"))

# STEP 3: CALCULATE MEAN/SE (ADJUSTED) -----

# Define survey design for overall dataset 
my_svy_adj <- svydesign(data=nhanes_adj, 
                          id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                          strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                          weights=~wtnew, # New sample weight
                          nest=TRUE)

# Create a survey design object for the subset of interest 
# Subsetting the original survey design object ensures we keep the 
# design information about the number of clusters and strata
my_svy_adj_sub <- subset(my_svy_adj, inAnalysis==1) # adjusted

# 1. To estimate the mean consumption among US adults 
# aged 20+ years who participated in the 2015-2018 cycles of NHANES. 
# Include means and standard errors.

# test out
svymean(~dairy_tot_adj, my_svy_adj_sub, na.rm = TRUE)

# test out dietary factors
svymean(~dairy_tot_adj+pf_soy_adj, my_svy_adj_sub, na.rm = TRUE)

# test with subgroups
svyby(~dairy_tot_adj, ~subgroup, my_svy_adj_sub, svymean)

# test with subgroups & dietary factors
svyby(~dairy_tot_adj+pf_soy_adj, ~subgroup, my_svy_adj_sub, svymean)

# CALCULATE: All foods

# add three new tot vars
diet_vars_adj
diet_vars_adj1 <- c(diet_vars_adj, "gr_tot_adj_grams", "veg_tot_adj_grams", "pf_tot_adj_grams", "fruit_tot_adj_grams")
diet_vars_adj1

allfoods_adj <- svymean(reformulate(diet_vars_adj1),
                          design = my_svy_adj_sub,
                          na.rm = TRUE) %>% as.data.frame()

# add food column
allfoods_adj1 <- rownames_to_column(allfoods_adj, "food")

# CALCULATE: All foods by subgroup

allfoods_adj_bysub <- svyby(reformulate(diet_vars_adj),
                              ~subgroup, 
                              my_svy_adj_sub, 
                              svymean)

# Reformat adjusted output to match model data
my_se_adj <- allfoods_adj_bysub %>% select(subgroup, starts_with("se."))

my_mean_adj <- allfoods_adj_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_adj_long <- my_se_adj %>% pivot_longer(cols = starts_with("se."),
                                                 names_to = "food",
                                                 names_prefix = "se.",
                                                 values_to = "SE")

my_mean_adj_long <- my_mean_adj %>% pivot_longer(cols = !subgroup,
                                                     names_to = "food",
                                                     values_to = "mean")

# combine
allfoods_adj_bysub_long <- left_join(my_mean_adj_long, my_se_adj_long, by = c("subgroup", "food"))

# Merge with diet factor description dataset

# edit diet factor dataset
diet_dat_adj <- diet_dat %>% mutate(Food_group = paste0(Food_group, "_adj"))

# join
allfoods_adj2 <- left_join(allfoods_adj1, diet_dat_adj, by = c("food" = "Food_group")) %>% 
  rename(food_label = Var_label,
         food_desc = Var_desc) %>% 
  arrange(food)

allfoods_adj_bysub_long1 <- left_join(allfoods_adj_bysub_long, diet_dat_adj, by = c("food" = "Food_group")) %>% 
  rename(food_label = Var_label,
         food_desc = Var_desc) %>% 
  arrange(subgroup, food)

# export
write_csv(allfoods_adj2, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_", export_date, ".csv"))

write_csv(allfoods_adj_bysub_long1, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_bysub_", export_date, ".csv"))

# EXTRA -----

# clean function

# test
# x <- allfoods_adj_bysub
# y <- "subgroup"

clean_func <- function(x, y){
  
  my_se <- x %>% select(y, starts_with("se."))
  my_mean <- x %>% select(y, !starts_with("se."))
  
  # transform both datsets to long
  my_se_long <- my_se %>% pivot_longer(cols = starts_with("se."),
                                       names_to = "food",
                                       names_prefix = c("se."),
                                       values_to = "se")
  
  my_mean_long <- my_mean %>% pivot_longer(cols = !y,
                                           names_to = "food",
                                           values_to = "mean")
  
  # join
  allfoods_bysub_long <- left_join(my_mean_long, my_se_long, by = c(y, "food"))
  
  # need to fix names
  dat <- allfoods_bysub_long %>% 
    mutate(food = gsub("_adj", "", food)) %>% 
    arrange(y, food)
  
  print(dat)
  
}


# Calculate mean/se by age, sex, and race separately

# age
age_dat <- 
  svyby(reformulate(names(nhanes_adj) %>% str_subset("_adj")),
      ~Age_label,
      my_svy_adj_sub,
      svymean)

age_dat_clean <- clean_func(age_dat, "Age_label")

# sex
sex_dat <- 
  svyby(reformulate(names(nhanes_adj) %>% str_subset("_adj")),
        ~Sex_label,
        my_svy_adj_sub,
        svymean)

sex_dat_clean <- clean_func(sex_dat, "Sex_label")

# race
race_dat <- 
  svyby(reformulate(names(nhanes_adj) %>% str_subset("_adj")),
        ~Race_label,
        my_svy_adj_sub,
        svymean)

race_dat_clean <- clean_func(race_dat, "Race_label")

# export

write_csv(age_dat_clean, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_byage_", export_date, ".csv"))

write_csv(sex_dat_clean, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_bysex_", export_date, ".csv"))

write_csv(race_dat_clean, 
          paste0("in/ALL PILLARS/Dietary intake/output data/NHANES_1518_summary_allfoods_adj_byrace_", export_date, ".csv"))

