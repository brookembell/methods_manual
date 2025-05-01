# Create data for Tableau
# 04-23-25

# SET UP -----

rm(list = ls())

library(tidyverse)
library(stringr)
# library(gtsummary)
options(scipen=999)

##### MUST OPEN 'METHODS_MANUAL' R PROJECT FIRST BEFORE RUNNING #####

# create vectors
output_folder_name <- "output_032025_1000sims"
cra_folder_name <- dir(paste0("outputs/model/", output_folder_name, "/CRA"))
costenv_folder_name <- dir(paste0("outputs/model/", output_folder_name, "/cost_env"))
costenv_both_folder_name <- costenv_folder_name %>% str_subset(pattern = "both")

# today's date
export_date <- "042325"

# ABSOLUTE CHANGE RESULTS, BY FOOD GROUP, ANNUAL TOTAL (FIGURE 2) -----

# (i) Health (Annual) -----

my_health_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name ,
                       "/CRA/", 
                       i, 
                       "/summarystats_attributable_USmortality_by_disease_type_2015_",
                       i,
                       ".csv")) %>% 
    select(disease_type, riskfactor, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_health_list[[i]] <- x
  
}

my_health_dat <- bind_rows(my_health_list)

# deal with dairy
my_health_dat_ <- my_health_dat %>% 
  filter(riskfactor == "dairy_tot") %>% 
  mutate(riskfactor = recode(riskfactor,
                             "dairy_tot" = "dairy_tot_calculated")) %>% 
  rbind(my_health_dat)

my_health_dat1 <- my_health_dat_ %>% 
  mutate(disease_type = ifelse(disease_type == "CVD", paste0(disease_type, " (deaths)"), paste0(disease_type, " (cases)"))) %>% 
  rename(outcome = disease_type, 
         food_group = riskfactor,
         impact_median_year = medians,
         UB_year = UB,
         LB_year = LB) %>% 
  mutate(impact_median_day = NA,
         LB_day = NA,
         UB_day = NA) %>% 
  relocate(food_group, .after = diet_pattern) %>% 
  arrange(diet_pattern, food_group, outcome)

# (ii) Cost & Environment (Annual) -----

my_costenv_list <- list()

for (i in costenv_both_folder_name) {
    
    x <- read_csv(paste0("outputs/model/", 
                         output_folder_name ,
                         "/cost_env/", 
                         i, 
                         "/By_SubGroup/summary.output_by_Foodgroup.costenv.csv")) %>% 
      select(Foodgroup, outcome, outcome_unit, 
             impact_median,	
             `impact_lower_bound (2.5th percentile)`,
             `impact_upper_bound (97.5th percentile)`,
             current_intake_impact_median,
             `current_intake_impact_lower_bound (2.5th percentile)`,
             `current_intake_impact_upper_bound (97.5th percentile)`,
             CF_intake_impact_median,
             `CF_intake_impact_lower_bound (2.5th percentile)`,
             `CF_intake_impact_upper_bound  (97.5th percentile)`) %>% 
      mutate(diet_pattern = paste0(i)) %>% 
      relocate(diet_pattern)
  
  my_costenv_list[[i]] <- x
  
}

my_costenv_dat <- bind_rows(my_costenv_list)

# tidy
my_costenv_dat1 <- my_costenv_dat %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
         impact_UB = `impact_upper_bound (97.5th percentile)`,
         current_intake_impact_LB = `current_intake_impact_lower_bound (2.5th percentile)`,
         current_intake_impact_UB = `current_intake_impact_upper_bound (97.5th percentile)`,
         CF_intake_impact_LB = `CF_intake_impact_lower_bound (2.5th percentile)`,
         CF_intake_impact_UB = `CF_intake_impact_upper_bound  (97.5th percentile)`) %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>%
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  relocate(diet_pattern) %>% 
  relocate(outcome, .after = food_group) %>% 
  arrange(diet_pattern, food_group, outcome)

# deal with dairy
moo <- my_costenv_dat1 %>% 
  filter(str_detect(food_group, "dairy")) %>% 
  arrange(diet_pattern, outcome)

moo_sum <- moo %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(across(impact_median:CF_intake_impact_UB, ~ sum(.x))) %>% 
  mutate(food_group = "dairy_tot_calculated") %>% 
  relocate(food_group, .after = diet_pattern)

# join with rest
my_costenv_dat1_ <- rbind(my_costenv_dat1, moo_sum) %>% 
  arrange(diet_pattern, food_group, outcome)

# add per day results
my_costenv_dat2 <- my_costenv_dat1_ %>% 
  select(diet_pattern, food_group, outcome, impact_median, impact_LB, impact_UB) %>%
  rename(impact_median_year = impact_median,
         LB_year = impact_LB,
         UB_year = impact_UB) %>% 
  mutate(impact_median_day = impact_median_year / 365,
         LB_day = LB_year / 365,
         UB_day = UB_year / 365)

# (iii) Combine all -----

# combine costenv and health
comb <- rbind(my_costenv_dat2, my_health_dat1) %>% 
  arrange(diet_pattern, food_group, outcome)

# create template for all dietary factors

diet_pattern <- comb %>% select(diet_pattern) %>% distinct()
food_group <- comb %>% select(food_group) %>% distinct()
outcome <- comb %>% select(outcome) %>% distinct()

skel <- merge(diet_pattern, food_group) %>% merge(outcome)

# merge with comb
full_comb <- left_join(skel, comb) %>% replace(is.na(.), 0)

# make health negative
full_comb1 <- full_comb %>% 
  mutate(impact_median_year = ifelse(outcome == "CVD (deaths)" | outcome == "Cancer (cases)", impact_median_year * -1, impact_median_year),
         LB_year = ifelse(outcome == "CVD (deaths)" | outcome == "Cancer (cases)", LB_year * -1, LB_year),
         UB_year = ifelse(outcome == "CVD (deaths)" | outcome == "Cancer (cases)", UB_year * -1, UB_year))

# read in map
map <- read_csv("manuscript_materials/figures/misc_data/food_categories.csv")

# merge
full_comb2 <- left_join(full_comb1, map, by = "food_group") %>% 
  relocate(food_cat, .before = food_group)

# deal with veg
veg_temp <- full_comb2 %>% 
  filter(food_group %in% c("veg_dg", "veg_ro", "veg_oth") & !(outcome %in% c("Cancer (cases)", "CVD (deaths)"))) %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(impact_median_year = sum(impact_median_year),
            LB_year = sum(LB_year),
            UB_year = sum(UB_year)) %>% 
  mutate(food_group = "veg_exc_sta")

# merge with
full_comb3 <- full_comb2 %>% 
  rows_update(veg_temp, by = c("diet_pattern", "outcome", "food_group"))

# export
write_csv(full_comb3, paste0("manuscript_materials/figures/tableau_data/abs_change_by_foodgroup_tableau_", export_date, ".csv"))

# export without date
write_csv(full_comb3, "manuscript_materials/figures/tableau_data/abs_change_by_foodgroup_tableau_final.csv")

# # export manuscript table
# comb1 <- comb %>% 
#   group_by(diet_pattern, outcome) %>% 
#   summarise(impact = sum(impact_median_year),
#             impact_LB = sum(LB_year),
#             impact_UB = sum(UB_year)) %>% 
#   mutate(impact = ifelse(outcome == "Cancer (cases)" | outcome == "CVD (deaths)", impact * -1, impact))
# 
# comb2 <- comb1 %>% 
#   pivot_wider(names_from = diet_pattern,
#               values_from = c(impact, impact_LB, impact_UB))
# 
# # whole numbers
# comb3 <- comb2 %>% mutate(across(where(is.numeric), round, 0))
# 
# # fix order
# comb4 <- comb3 %>% select(outcome, ends_with("Med"), ends_with("US"), ends_with("Veg"), ends_with("Vegan"))
# 
# write_csv(comb4, "tables_figures/manuscript/Table- Absolute change.csv")

# PERCENT CHANGE RESULTS, TOTAL (FIGURE 1) -----

# (i) Cost/enviro/FL -----

pc <- my_costenv_dat1 %>% 
  select(-c(impact_median, impact_LB, impact_UB))

# calculate percent change at the pattern-level
pc1 <- pc %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(total_impact_current = sum(current_intake_impact_median),
            total_LB_current = sum(current_intake_impact_LB),
            total_UB_current = sum(current_intake_impact_UB),
            
            total_impact_CF = sum(CF_intake_impact_median),
            total_LB_CF = sum(CF_intake_impact_LB),
            total_UB_CF = sum(CF_intake_impact_UB)) %>% 
  mutate(perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100,
         perc_change_LB = ((total_LB_CF - total_LB_current) / total_LB_current) * 100,
         perc_change_UB = ((total_UB_CF - total_UB_current) / total_UB_current) * 100) %>% 
  arrange(outcome)

pc2 <- pc1 %>% 
  select(diet_pattern, outcome, perc_change, perc_change_LB, perc_change_UB)

# (ii) Health -----

# total (use joint effects)
joint_effects_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name,
                       "/CRA/", 
                       i, 
                       "/joint/summarystats_joint_attributable_USmortality_by_disease_type_2015_",
                       i,
                       ".csv")) %>% 
    select(disease_type, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  joint_effects_list[[i]] <- x
  
}

my_joint_dat <- bind_rows(joint_effects_list)

my_joint_dat1 <- my_joint_dat %>% 
  mutate(disease_type = ifelse(disease_type == "CVD", paste0(disease_type, " (deaths)"), paste0(disease_type, " (cases)"))) %>% 
  rename(outcome = disease_type, 
         # food_group = riskfactor,
         impact_median_year = medians,
         UB_year = UB,
         LB_year = LB) %>% 
  mutate(impact_median_day = NA,
         LB_day = NA,
         UB_day = NA) %>% 
  # relocate(food_group, .after = diet_pattern) %>% 
  arrange(diet_pattern, outcome)

pc_health_joint <- my_joint_dat1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(total_impact_shift = sum(impact_median_year),
            total_LB_shift = sum(LB_year),
            total_UB_shift = sum(UB_year))

# by food group only
# pc_health <- my_health_dat1 %>% 
#   group_by(diet_pattern, outcome) %>% 
#   summarise(total_impact_shift = sum(impact_median_year),
#             total_LB_shift = sum(LB_year),
#             total_UB_shift = sum(UB_year))

# import 2018 cancer/cvd numbers
cancer <- read_csv("data_inputs/FINAL/cleaned_raw_data/cancer_incidence_2025-03-11_FINAL.csv")
cvd <- read_csv("data_inputs/FINAL/cleaned_raw_data/cvd_mortality_2025-03-11_FINAL.csv")

cancer1 <- cancer %>% 
  filter(diseases != "ALL") %>% 
  group_by(diseases) %>% 
  summarise(cancer_sum = sum(count)) %>% 
  summarise(cancer_cases = sum(cancer_sum)) %>% 
  as.numeric()

cvd1 <- cvd %>% 
  select(-c(TSTK, Age, Sex, Race, contains(c("se_", "medBMI", "medSBP")))) %>% 
  rowwise() %>% 
  mutate(cvd_sum = sum(c_across(AA:RHD))) %>%
  select(subgroup, cvd_sum) %>% 
  ungroup() %>% 
  summarise(cvd_deaths = sum(cvd_sum)) %>% 
  as.numeric()

# add to dataframe

# total (joint)
pc_health_joint1 <- pc_health_joint %>% 
  rowwise() %>% 
  mutate(total_impact_current = ifelse(outcome == "Cancer (cases)", cancer1, cvd1),
         total_LB_current = total_impact_current,
         total_UB_current = total_impact_current,
         
         total_impact_CF = total_impact_current - total_impact_shift,
         total_LB_CF = total_impact_current - total_LB_shift,
         total_UB_CF = total_impact_current - total_UB_shift,
         
         perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100,
         perc_change_LB = ((total_LB_CF - total_LB_current) / total_LB_current) * 100,
         perc_change_UB = ((total_UB_CF - total_UB_current) / total_UB_current) * 100)


pc_health_joint2 <- pc_health_joint1 %>% 
  select(diet_pattern, outcome, perc_change, perc_change_UB, perc_change_LB)

# by subgroup
# pc_health1 <- pc_health %>% 
#   rowwise() %>% 
#   mutate(total_impact_current = ifelse(outcome == "Cancer (cases)", cancer1, cvd1),
#          total_LB_current = total_impact_current,
#          total_UB_current = total_impact_current,
#          
#          total_impact_CF = total_impact_current - total_impact_shift,
#          total_LB_CF = total_impact_current - total_LB_shift,
#          total_UB_CF = total_impact_current - total_UB_shift,
# 
#          perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100,
#          perc_change_LB = ((total_LB_CF - total_LB_current) / total_LB_current) * 100,
#          perc_change_UB = ((total_UB_CF - total_UB_current) / total_UB_current) * 100)
# 
# 
# pc_health2 <- pc_health1 %>% 
#   select(diet_pattern, outcome, perc_change, perc_change_UB, perc_change_LB)

# (iii) combine costenv and health -----

# use joint health effects for this dataset
all <- rbind(pc2, pc_health_joint2) %>% 
  arrange(outcome) %>% 
  relocate(perc_change_UB, .after = perc_change)

# fix negative UIs
all1 <- all %>% 
  mutate(perc_change_UB_new = ifelse(perc_change < 0, perc_change_LB, perc_change_UB),
         perc_change_LB_new = ifelse(perc_change < 0, perc_change_UB, perc_change_LB))

# export
write_csv(all1, paste0("manuscript_materials/figures/tableau_data/perc_change_tableau_", export_date, ".csv"))
write_csv(all1, "manuscript_materials/figures/tableau_data/perc_change_tableau_final.csv")

# PERCENT CHANGE RESULTS, BY FOOD GROUP -----

# NOT SURE WHAT THIS WAS USED FOR?

# a <- comb %>% 
#   select(-c(impact_median_day, LB_day, UB_day)) %>% 
#   group_by(diet_pattern, outcome) %>% 
#   mutate(sum = sum(impact_median_year),
#          sum_LB = sum(LB_year),
#          sum_UB = sum(UB_year)) %>% 
#   arrange(diet_pattern, outcome)
# 
# a1 <- a %>% 
#   mutate(prop = impact_median_year / sum * 100,
#          prop_LB = LB_year / sum_LB * 100,
#          prop_UB = UB_year / sum_UB * 100)
# 
# # check
# a1 %>% 
#   group_by(diet_pattern, outcome) %>% 
#   summarise(sum(prop),
#             sum(prop_LB),
#             sum(prop_UB))
# 
# # export
# write_csv(a1, paste0("manuscript_materials/figures/tableau_data/perc_change_byfood_tableau_", export_date, ".csv"))
# write_csv(a1, "manuscript_materials/figures/tableau_data/perc_change_byfood_tableau_final.csv")

# PERCENT CHANGE RESULTS, BY POP SUBGROUP (FIGURE 3) -----

# (i) Health -----

my_health_pop_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name ,
                       "/CRA/", 
                       i, 
                       "/summarystats_attributable_USmortality_by_age_female_disease_type_2015_",
                       i,
                       ".csv")) %>% 
    select(age, female, disease_type, riskfactor, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_health_pop_list[[i]] <- x
  
}

my_health_pop_dat <- bind_rows(my_health_pop_list)

my_health_pop_dat1 <- my_health_pop_dat %>% 
  mutate(disease_type = ifelse(disease_type == "CVD", paste0(disease_type, " (deaths)"), paste0(disease_type, " (cases)"))) %>% 
  rename(outcome = disease_type, 
         food_group = riskfactor,
         impact_median_year = medians,
         UB_year = UB,
         LB_year = LB) %>% 
  mutate(impact_median_day = NA,
         LB_day = NA,
         UB_day = NA) %>% 
  relocate(food_group, .after = diet_pattern) %>% 
  arrange(diet_pattern, food_group, outcome)

h <- my_health_pop_dat1 %>% 
  group_by(diet_pattern, outcome, age, female) %>% 
  summarise(impact_median_year = ceiling(sum(impact_median_year)))

cancer_sub <- cancer %>% 
  filter(diseases == "ALL") %>% 
  select(Age, Sex, Race, count) %>% 
  mutate(outcome = "Cancer (cases)") %>% 
  relocate(outcome, .before = count)

cvd_sub <- cvd %>% 
  select(-c(TSTK, subgroup, contains(c("se_", "medBMI", "medSBP")))) %>% 
  rowwise() %>% 
  mutate(count = sum(c_across(AA:RHD))) %>%
  select(Age, Sex, Race, count) %>% 
  mutate(outcome = "CVD (deaths)") %>% 
  relocate(outcome, .before = count)

disease_comb <- rbind(cancer_sub, cvd_sub) %>% 
  arrange(Age, Sex, Race, outcome) %>% 
  mutate(age = case_when(Age == 1 ~ 25,
                         Age == 2 ~ 35,
                         Age == 3 ~ 45,
                         Age == 4 ~ 55,
                         Age == 5 ~ 65,
                         Age == 6 ~ 75),
         female = case_when(Sex == 1 ~ 1,
                            Sex == 2 ~ 0)) %>% 
  rename(race = Race) %>% 
  relocate(age, female) %>% 
  select(-c(Age, Sex))

disease_comb1 <- disease_comb %>% 
  group_by(age, female, outcome) %>% 
  summarise(count = sum(count))

h1 <- left_join(h, disease_comb1, by = c("age", "female", "outcome"))

h2 <- h1 %>% 
  mutate(new = count - impact_median_year,
         old = count,
         perc_change = ((new - old) / old) * 100)

# (ii) Cost & Environment -----

my_costenv_pop_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name ,
                       "/cost_env/", 
                       i, 
                       "/By_SubGroup/summary.output_by_age_gp_sex_gp_race_gp_Foodgroup.costenv.csv")) %>% 
    select(age_gp, sex_gp, race_gp,
      Foodgroup, outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound (97.5th percentile)`,
           current_intake_impact_median,
           `current_intake_impact_lower_bound (2.5th percentile)`,
           `current_intake_impact_upper_bound (97.5th percentile)`,
           CF_intake_impact_median,
           `CF_intake_impact_lower_bound (2.5th percentile)`,
           `CF_intake_impact_upper_bound  (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_costenv_pop_list[[i]] <- x
  
}

my_costenv_pop_dat <- bind_rows(my_costenv_pop_list) %>% arrange(diet_pattern, outcome)


my_costenv_pop_dat1 <- my_costenv_pop_dat %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  rename(LB = `impact_lower_bound (2.5th percentile)`,
         UB = `impact_upper_bound (97.5th percentile)`,
         current_intake_impact_LB = `current_intake_impact_lower_bound (2.5th percentile)`,
         current_intake_impact_UB = `current_intake_impact_upper_bound (97.5th percentile)`,
         CF_intake_impact_LB = `CF_intake_impact_lower_bound (2.5th percentile)`,
         CF_intake_impact_UB = `CF_intake_impact_upper_bound  (97.5th percentile)`) %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>%
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  relocate(diet_pattern) %>% 
  relocate(outcome, .after = food_group) %>% 
  arrange(diet_pattern, food_group, outcome)

# add per day results
# I don't think I need to do this?
my_costenv_pop_dat2 <- my_costenv_pop_dat1 %>% 
  rename(impact_median_year = impact_median,
         LB_year = LB,
         UB_year = UB) %>% 
  mutate(impact_median_day = impact_median_year / 365,
         LB_day = LB_year / 365,
         UB_day = UB_year / 365)
  
# calculate percent change at the pattern-level
my_costenv_pop_dat3 <- my_costenv_pop_dat2 %>% 
  group_by(diet_pattern, outcome, age_gp, sex_gp) %>% 
  summarise(total_impact_current = sum(current_intake_impact_median),
            total_LB_current = sum(current_intake_impact_LB),
            total_UB_current = sum(current_intake_impact_UB),
            
            total_impact_CF = sum(CF_intake_impact_median),
            total_LB_CF = sum(CF_intake_impact_LB),
            total_UB_CF = sum(CF_intake_impact_UB)) %>% 
  mutate(perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100,
         perc_change_LB = ((total_LB_CF - total_LB_current) / total_LB_current) * 100,
         perc_change_UB = ((total_UB_CF - total_UB_current) / total_UB_current) * 100) %>% 
  arrange(outcome)

# export
# write_csv(koo3, paste0("tables_figures/manuscript/data/perc_change_bysubgroup_tableau_", export_date, ".csv"))

my_costenv_pop_dat4 <- my_costenv_pop_dat3 %>% 
  select(diet_pattern, outcome, age_gp, sex_gp, starts_with("perc_change"))

h3 <- h2 %>% 
  select(diet_pattern, outcome, age, female, perc_change) %>% 
  mutate(perc_change_LB = NA,
         perc_change_UB = NA,
         age_gp = case_when(age == 25 ~ "20-34",
                            age == 35 ~ "35-44",
                            age == 45 ~ "45-54",
                            age == 55 ~ "55-64",
                            age == 65 ~ "65-74",
                            age == 75 ~ "75+"),
         sex_gp = case_when(female == 1 ~ "Female",
                            female == 0 ~ "Male")) %>% 
  ungroup() %>% 
  select(-c(age, female))

# merge health and others
new <- rbind(my_costenv_pop_dat4, h3)

# fix negative UIs
new1 <- new %>% 
  mutate(perc_change_UB_new = ifelse(perc_change < 0, perc_change_LB, perc_change_UB),
         perc_change_LB_new = ifelse(perc_change < 0, perc_change_UB, perc_change_LB))

# export
write_csv(new1, paste0("manuscript_materials/figures/tableau_data/perc_change_bysubgroup_tableau_", export_date, ".csv"))
write_csv(new1, "manuscript_materials/figures/tableau_data/perc_change_bysubgroup_tableau_final.csv")



# ABSOLUTE COST/ENVIRO/HEALTH CHANGE RESULTS (10% SHIFT) -----

# (i) cost/enviro -----

my_costenv_tot_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name ,
                       "/cost_env/", 
                       i, 
                       "/By_SubGroup/summary.output_by_all.costenv.csv")) %>% 
    select(outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_costenv_tot_list[[i]] <- x
  
}

my_costenv_tot_dat <- bind_rows(my_costenv_tot_list)

my_costenv_tot_dat1 <- my_costenv_tot_dat %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  arrange(diet_pattern_new, outcome)

my_costenv_tot_dat2 <- my_costenv_tot_dat1 %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>% 
  rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
         impact_UB = `impact_upper_bound (97.5th percentile)`,
         diet_pattern = diet_pattern_new,
         outcome = outcome_new) %>% 
  relocate(diet_pattern, outcome) %>% 
  mutate(impact_median_10perc = (impact_median / 10) * 365,
         impact_LB_10perc = (impact_LB / 10) * 365,
         impact_UB_10perc = (impact_UB / 10) * 365) 

# (ii) health

my_health_tot_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("outputs/model/", 
                       output_folder_name ,
                       "/CRA/", 
                       i, 
                       "/summarystats_attributable_USmortality_by_disease_type_2015_",
                       i,
                       ".csv")) %>% 
    select(disease_type, riskfactor, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_health_tot_list[[i]] <- x
  
}

my_health_tot_dat <- bind_rows(my_health_tot_list)

my_health_tot_dat1 <- my_health_tot_dat %>% 
  mutate(disease_type = ifelse(disease_type == "CVD", paste0(disease_type, " (deaths)"), paste0(disease_type, " (cases)"))) %>% 
  rename(outcome = disease_type, 
         food_group = riskfactor,
         impact_median = medians,
         impact_LB = LB,
         impact_UB = UB) %>% 
  mutate(impact_median_day = NA) %>% 
  relocate(food_group, .after = diet_pattern) %>% 
  arrange(diet_pattern, food_group, outcome)

my_health_tot_dat2 <- my_health_tot_dat1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(impact_median = sum(impact_median),
            impact_LB = sum(impact_LB),
            impact_UB = sum(impact_UB)) %>% 
  mutate(impact_median_10perc = (impact_median / 10),
         impact_LB_10perc = (impact_LB / 10),
         impact_UB_10perc = (impact_UB / 10)) 

# (iii) combine costenv and health
comb_new <- rbind(my_costenv_tot_dat2, my_health_tot_dat2) %>% 
  arrange(diet_pattern, outcome)

# export
write_csv(comb_new, paste0("manuscript_materials/figures/tableau_data/abs_change_10perc_tableau_long_", export_date, ".csv"))
write_csv(comb_new, "manuscript_materials/figures/tableau_data/abs_change_10perc_tableau_long_final.csv")

# pivot wider
results_10perc <- comb_new %>% 
  select(-c(impact_median, impact_UB, impact_LB)) %>% 
  pivot_wider(id_cols = c(outcome),
              names_from = diet_pattern,
              values_from = starts_with("impact")) %>% 
  select(outcome, ends_with("Med"), ends_with("US"), ends_with("Veg"), ends_with("Vegan"))

# export
write_csv(results_10perc, paste0("manuscript_materials/figures/tableau_data/abs_change_10perc_tableau_", export_date, ".csv"))
write_csv(results_10perc, "manuscript_materials/figures/tableau_data/abs_change_10perc_tableau_final.csv")

# prepare manuscript table
# write_csv(results_10perc, paste0("tables_figures/manuscript/Table- Absolute change (10% shift).csv"))
