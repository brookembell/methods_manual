# Energy adjustment of diet variables
# Author: Brooke Bell
# Date: 2-03-25

# STEP 0: SET-UP -----

rm(list=ls())

# load packages
library(tidyverse)
library(modelr)
library(survey)

# STEP 1: IMPORT CLEANED NHANES DATASET -----

nhanes <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_incl_ssb_clean.rds") %>% 
  ungroup() # get rid of rowwise formatting

nhanes1 <- nhanes %>% 
  select(-c(kcal:afs_tot, ssb)) %>%
  relocate(c(wtnew:inAnalysis), .before = fruit_juice_1)

# STEP 2: RESIDUAL METHOD -----

# wide to long
nhanes_long <- pivot_longer(nhanes1, 
                            cols = ends_with(c("_1", "_2")),
                            names_to = "names_temp",
                            values_to = "values_temp")

nhanes_long1 <- nhanes_long %>% separate(names_temp, into=c("name", "day"), sep = "_(?=[^_]+$)")

nhanes_long2 <- nhanes_long1 %>% 
  pivot_wider(names_from = "name", values_from = "values_temp")

# new code translated from Peylin Stata code
nhanes2 <- nhanes_long2 %>% mutate(calories = kcal,
                         meancalories = mean(calories, na.rm = TRUE),
                         log_calories = log(calories),
                         log_meancalories = log(meancalories),
                         log_2000 = log(2000))

# 7 people have kcal=0
nhanes2 %>% filter(log_calories == "-Inf" & inAnalysis == "TRUE") %>% View()

# if logcalories is -Inf, change to NA
nhanes3 <- nhanes2 %>% 
  mutate(log_calories = ifelse(log_calories == "-Inf", NA, log_calories)) %>% 
  arrange(SEQN, day)

# check
nhanes3 %>% filter(log_calories == "-Inf" & inAnalysis == "TRUE") #good

# debug
# x <- nhanes1
# y <- "sodium"

resid_function <- function(x, y){
  
  dat <- x
  
  dat[["var_tem"]] <- dat[[y]] 
  
  dat1 <- dat %>% mutate(log_var_tem = ifelse(var_tem > 0, log(var_tem), NA))
  
  mod <- lm(log_var_tem ~ log_calories, data = dat1)
  
  a = summary(mod)$coefficients["(Intercept)", "Estimate"]
  b = summary(mod)$coefficients["log_calories", "Estimate"]
  
  dat_new <- dat1 %>% 
    add_residuals(mod) %>% 
    rowwise() %>% 
    mutate(log_cons_var_tem = a + (b * log_2000),
           a_log_var_tem = log_cons_var_tem + resid,
           a_var_tem = ifelse(var_tem == 0, 0,exp(a_log_var_tem)),
           "{y}_adj" := a_var_tem)
  
  dat_new1 <- dat_new %>% arrange(SEQN, day) %>% select(paste0(y, "_adj"))

  print(dat_new1)  
  
}

# test
resid_function(nhanes3, "pf_pm")      
resid_function(nhanes3, "fruit_exc_juice") 
resid_function(nhanes3, "sodium")      

# create vector of dietary factors

diet_vars <- read_csv("in/ALL PILLARS/Dietary intake/raw data/dietary_factors_010424_FINAL.csv") %>%
  select(Food_group) %>%
  unlist() %>%
  as.vector()

nums <- which(variable.names(nhanes3) %in% diet_vars)

new_diet_vars <- variable.names(nhanes3[nums])

# apply function to all dietary factors
resid_list <- list()

for (i in new_diet_vars) {
  
  resid_list[[i]] <- resid_function(nhanes3, i)
  
}

# nhanes with adjusted vars
nhanes_adj <- nhanes3 %>% 
  cbind(bind_cols(resid_list))

# check a few diet vars
nhanes_adj %>% select(ssb, ssb_adj) %>% View()
nhanes_adj %>% select(fruit_exc_juice, fruit_exc_juice_adj) %>% View()
nhanes_adj %>% select(pf_ns, pf_ns_adj) %>% View()
nhanes_adj %>% select(pf_redm_tot, pf_redm_tot_adj) %>% View()
nhanes_adj %>% select(pf_poultry_tot, pf_poultry_tot_adj) %>% View()


# export data
write_rds(nhanes_adj,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_long.rds")

write_csv(nhanes_adj,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_long.csv")

# pivot to wide
nhanes_adj_wide <- nhanes_adj %>% pivot_wider(id_cols = SEQN:inAnalysis,
                           names_from = day,
                           values_from = ends_with("_adj"))

# calculate averages
nhanes_adj_wide1 <- nhanes_adj_wide %>%
  rowwise() %>%
  mutate(sat_fat_adj = mean(c(sat_fat_adj_1, sat_fat_adj_2), na.rm = TRUE),
         sodium_adj = mean(c(sodium_adj_1, sodium_adj_2), na.rm = TRUE),
         gr_refined_adj = mean(c(gr_refined_adj_1, gr_refined_adj_2), na.rm = TRUE),
         gr_whole_adj = mean(c(gr_whole_adj_1, gr_whole_adj_2), na.rm = TRUE),
         added_sugar_adj = mean(c(added_sugar_adj_1, added_sugar_adj_2), na.rm = TRUE),
         fruit_tot_adj = mean(c(fruit_tot_adj_1, fruit_tot_adj_2), na.rm = TRUE),
         fruit_exc_juice_adj = mean(c(fruit_exc_juice_adj_1, fruit_exc_juice_adj_2), na.rm = TRUE),
         fruit_juice_adj = mean(c(fruit_juice_adj_1, fruit_juice_adj_2), na.rm = TRUE),
         fiber_adj = mean(c(fiber_adj_1, fiber_adj_2), na.rm = TRUE),
         dairy_tot_adj = mean(c(dairy_tot_adj_1, dairy_tot_adj_2), na.rm = TRUE),
         dairy_cow_adj = mean(c(dairy_cow_adj_1, dairy_cow_adj_2), na.rm = TRUE),
         dairy_soy_adj = mean(c(dairy_soy_adj_1, dairy_soy_adj_2), na.rm = TRUE),
         veg_dg_adj = mean(c(veg_dg_adj_1, veg_dg_adj_2), na.rm = TRUE),
         veg_oth_adj = mean(c(veg_oth_adj_1, veg_oth_adj_2), na.rm = TRUE),
         veg_ro_adj = mean(c(veg_ro_adj_1, veg_ro_adj_2), na.rm = TRUE),
         veg_sta_adj = mean(c(veg_sta_adj_1, veg_sta_adj_2), na.rm = TRUE),
         veg_leg_adj = mean(c(veg_leg_adj_1, veg_leg_adj_2), na.rm = TRUE),
         veg_exc_sta_adj = mean(c(veg_exc_sta_adj_1, veg_exc_sta_adj_2), na.rm = TRUE),
         oil_adj = mean(c(oil_adj_1, oil_adj_2), na.rm = TRUE),
         pf_egg_adj = mean(c(pf_egg_adj_1, pf_egg_adj_2), na.rm = TRUE),
         pf_ns_adj = mean(c(pf_ns_adj_1, pf_ns_adj_2), na.rm = TRUE),
         pf_soy_adj = mean(c(pf_soy_adj_1, pf_soy_adj_2), na.rm = TRUE),
         pf_poultry_adj = mean(c(pf_poultry_adj_1, pf_poultry_adj_2), na.rm = TRUE),
         pf_poultry_tot_adj = mean(c(pf_poultry_tot_adj_1, pf_poultry_tot_adj_2), na.rm = TRUE),
         pf_pm_adj = mean(c(pf_pm_adj_1, pf_pm_adj_2), na.rm = TRUE),
         pf_redm_adj = mean(c(pf_redm_adj_1, pf_redm_adj_2), na.rm = TRUE),
         pf_redm_tot_adj = mean(c(pf_redm_tot_adj_1, pf_redm_tot_adj_2), na.rm = TRUE),
         # pf_organ_adj = mean(c(pf_organ_adj_1, pf_organ_adj_2), na.rm = TRUE),
         pf_leg_adj = mean(c(pf_leg_adj_1, pf_leg_adj_2), na.rm = TRUE),
         sea_omega3_fa_adj = mean(c(sea_omega3_fa_adj_1, sea_omega3_fa_adj_2), na.rm = TRUE),
         pufa_energy_adj = mean(c(pufa_energy_adj_1, pufa_energy_adj_2), na.rm = TRUE),
         sfat_energy_adj = mean(c(sfat_energy_adj_1, sfat_energy_adj_2), na.rm = TRUE),
         pf_seafood_adj = mean(c(pf_seafood_adj_1, pf_seafood_adj_2), na.rm = TRUE),
         leg_tot_adj = mean(c(leg_tot_adj_1, leg_tot_adj_2), na.rm = TRUE),
         pf_animal_adj = mean(c(pf_animal_adj_1, pf_animal_adj_2), na.rm = TRUE),
         pf_plant_adj = mean(c(pf_plant_adj_1, pf_plant_adj_2), na.rm = TRUE),
         ssb_adj = mean(c(ssb_adj_1, ssb_adj_2), na.rm=TRUE),
         
         pf_tot_adj = mean(c(pf_tot_adj_1, pf_tot_adj_2), na.rm=TRUE),
         gr_tot_adj = mean(c(gr_tot_adj_1, gr_tot_adj_2), na.rm=TRUE),
         afs_tot_adj = mean(c(afs_tot_adj_1, afs_tot_adj_2), na.rm=TRUE),
         veg_tot_adj = mean(c(veg_tot_adj_1, veg_tot_adj_2), na.rm=TRUE))

# added 8/26/24
# calculate food group means as grams

nhanes_adj_wide2 <- nhanes_adj_wide1 %>% 
  rowwise() %>% 
  mutate(veg_dg_adj_grams = veg_dg_adj * 118 ,
         veg_oth_adj_grams = veg_oth_adj * 140,
         veg_ro_adj_grams = veg_ro_adj * 144,
         veg_sta_adj_grams = veg_sta_adj * 134,
         veg_tot_adj_grams = sum(veg_dg_adj_grams, 
                                 veg_oth_adj_grams,
                                 veg_ro_adj_grams,
                                 veg_sta_adj_grams),
         
         gr_refined_adj_grams = gr_refined_adj * 36,
         gr_whole_adj_grams = gr_whole_adj * 51,
         gr_tot_adj_grams = sum(gr_refined_adj_grams,
                                gr_whole_adj_grams),
         
         pf_egg_adj_grams = pf_egg_adj * 50,
         pf_poultry_tot_adj_grams = pf_poultry_tot_adj * 29,
         pf_redm_tot_adj_grams = pf_redm_tot_adj * 31,
         pf_seafood_adj_grams = pf_seafood_adj * 29,
         pf_ns_adj_grams = pf_ns_adj * 15,
         leg_tot_adj_grams = leg_tot_adj * 37,
         pf_tot_adj_grams = sum(pf_egg_adj_grams,
                                pf_poultry_tot_adj_grams,
                                pf_redm_tot_adj_grams,
                                pf_seafood_adj_grams,
                                pf_ns_adj_grams,
                                leg_tot_adj_grams),
         
         fruit_exc_juice_adj_grams = fruit_exc_juice_adj * 152,
         fruit_juice_adj_grams = fruit_juice_adj * 251,
         fruit_tot_adj_grams = sum(fruit_exc_juice_adj_grams,
                                   fruit_juice_adj_grams))

# get rid of NaN
nhanes_adj_wide2[nhanes_adj_wide2 == "NaN"] <- NA

# export data
write_rds(nhanes_adj_wide2,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_wide.rds")

write_csv(nhanes_adj_wide2,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_wide.csv",
          na = "")

