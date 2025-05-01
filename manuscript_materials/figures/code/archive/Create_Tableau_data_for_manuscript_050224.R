# Create data for Tableau
# 05-02-24

# SET UP -----

rm(list = ls())
library(tidyverse)
library(stringr)
# library(gtsummary)
options(scipen=999)

# create vectors
output_folder_name <- "output_013124_1000sims"
cra_folder_name <- dir(paste0("out/", output_folder_name, "/CRA"))
costenv_folder_name <- dir(paste0("out/", output_folder_name, "/cost_env"))
costenv_both_folder_name <- costenv_folder_name %>% str_subset(pattern = "both")

export_date <- "050224"

# ABSOLUTE CHANGE RESULTS -----

# (i) Health -----

my_health_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("out/", 
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

my_health_dat1 <- my_health_dat %>% 
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

# (ii) Cost & Environment -----

my_costenv_list <- list()

for (i in costenv_both_folder_name) {
    
    x <- read_csv(paste0("out/", 
                         output_folder_name ,
                         "/cost_env/", 
                         i, 
                         "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv")) %>% 
      select(Foodgroup, outcome, outcome_unit, 
             impact_median,	
             `impact_lower_bound (2.5th percentile)`,
             `impact_upper_bound_median (97.5th percentile)`,
             current_intake_impact_median,
             `current_intake_impact_lower_bound (2.5th percentile)`,
             `current_intake_impact_upper_bound_median  (97.5th percentile)`,
             CF_intake_impact_median,
             `CF_intake_impact_lower_bound (2.5th percentile)`,
             `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
      mutate(diet_pattern = paste0(i)) %>% 
      relocate(diet_pattern)
  
  my_costenv_list[[i]] <- x
  
}

my_costenv_dat <- bind_rows(my_costenv_list)

# (iii) Forced labor (temporary) -----

my_fl_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("out/output_021524_1000sims_FLonly/cost_env/", 
                       i, 
                       "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv")) %>% 
    select(Foodgroup, outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound_median (97.5th percentile)`,
           current_intake_impact_median,
           `current_intake_impact_lower_bound (2.5th percentile)`,
           `current_intake_impact_upper_bound_median  (97.5th percentile)`,
           CF_intake_impact_median,
           `CF_intake_impact_lower_bound (2.5th percentile)`,
           `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_fl_list[[i]] <- x
  
}

my_fl_dat <- bind_rows(my_fl_list)

# (iv) Combine enviro, cost, FL -----

temp <- rbind(my_costenv_dat, my_fl_dat) %>% arrange(diet_pattern, outcome)

my_costenv_dat1 <- temp %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  rename(LB_day = `impact_lower_bound (2.5th percentile)`,
         UB_day = `impact_upper_bound_median (97.5th percentile)`,
         current_intake_impact_LB = `current_intake_impact_lower_bound (2.5th percentile)`,
         current_intake_impact_UB = `current_intake_impact_upper_bound_median  (97.5th percentile)`,
         CF_intake_impact_LB = `CF_intake_impact_lower_bound (2.5th percentile)`,
         CF_intake_impact_UB = `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>%
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  relocate(diet_pattern) %>% 
  relocate(outcome, .after = food_group) %>% 
  arrange(diet_pattern, food_group, outcome)

# add per year results
my_costenv_dat2 <- my_costenv_dat1 %>% 
  select(diet_pattern, food_group, outcome, impact_median, LB_day, UB_day) %>%
  mutate(impact_median_year = impact_median * 365,
         LB_year = LB_day * 365,
         UB_year = UB_day * 365) %>% 
  rename(impact_median_day = impact_median)

# (v) Combine all -----

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
map <- read_csv("tables_figures/food_categories.csv")

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
write_csv(full_comb3, paste0("tables_figures/manuscript/data/abs_change_by_foodgroup_tableau_", export_date, ".csv"))

# export manuscript table
comb1 <- comb %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(impact = sum(impact_median_year),
            impact_LB = sum(LB_year),
            impact_UB = sum(UB_year)) %>% 
  mutate(impact = ifelse(outcome == "Cancer (cases)" | outcome == "CVD (deaths)", impact * -1, impact))

comb2 <- comb1 %>% 
  pivot_wider(names_from = diet_pattern,
              values_from = c(impact, impact_LB, impact_UB))

# whole numbers
comb3 <- comb2 %>% mutate(across(where(is.numeric), round, 0))

# fix order
comb4 <- comb3 %>% select(outcome, ends_with("Med"), ends_with("US"), ends_with("Veg"), ends_with("Vegan"))

write_csv(comb4, "tables_figures/manuscript/Table- Absolute change.csv")

# PERCENT CHANGE RESULTS -----

# (i) Cost/enviro/FL -----

pc <- my_costenv_dat1 %>% 
  select(-c(impact_median, LB_day, UB_day))

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
pc_health <- my_health_dat1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(total_impact_shift = sum(impact_median_year),
            total_LB_shift = sum(LB_year),
            total_UB_shift = sum(UB_year))

# import 2018 cancer/cvd numbers
cancer <- read_csv("in/FINAL/raw_data/cancer_incidence_012624_FINAL.csv")
cvd <- read_csv("in/FINAL/raw_data/cvd_mortality_012624_FINAL.csv")

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
pc_health1 <- pc_health %>% 
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


pc_health2 <- pc_health1 %>% 
  select(diet_pattern, outcome, perc_change, perc_change_UB, perc_change_LB)

# (iii) combine costenv and health -----
all <- rbind(pc2, pc_health2) %>% 
  arrange(outcome) %>% 
  relocate(perc_change_UB, .after = perc_change)

# fix negative UIs

all1 <- all %>% 
  mutate(perc_change_UB_new = ifelse(perc_change < 0, perc_change_LB, perc_change_UB),
         perc_change_LB_new = ifelse(perc_change < 0, perc_change_UB, perc_change_LB))

# export
write_csv(all1, paste0("tables_figures/manuscript/data/perc_change_tableau_", export_date, ".csv"))

# ABSOLUTE COST/ENVIRO/HEALTH CHANGE RESULTS (10% SHIFT) -----

# (i) Forced labor (temporary) -----

my_fl_tot_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("out/output_021524_1000sims_FLonly/cost_env/", 
                       i, 
                       "/By_SubGroup/summary.output_by_all.costenv.csv")) %>% 
    select(outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound_median (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_fl_tot_list[[i]] <- x
  
}

my_fl_tot_dat <- bind_rows(my_fl_tot_list)

# (ii) cost/enviro -----

my_costenv_tot_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("out/", 
                       output_folder_name ,
                       "/cost_env/", 
                       i, 
                       "/By_SubGroup/summary.output_by_all.costenv.csv")) %>% 
    select(outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound_median (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_costenv_tot_list[[i]] <- x
  
}

my_costenv_tot_dat <- bind_rows(my_costenv_tot_list)

# (iii) Combine FL and costenv

foo <- rbind(my_costenv_tot_dat, my_fl_tot_dat)


my_costenv_tot_dat1 <- foo %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  arrange(diet_pattern_new, outcome)

my_costenv_tot_dat2 <- my_costenv_tot_dat1 %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>% 
  rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
         impact_UB = `impact_upper_bound_median (97.5th percentile)`,
         diet_pattern = diet_pattern_new,
         outcome = outcome_new) %>% 
  relocate(diet_pattern, outcome) %>% 
  mutate(impact_median_10perc = (impact_median / 10) * 365,
         impact_LB_10perc = (impact_LB / 10) * 365,
         impact_UB_10perc = (impact_UB / 10) * 365) 

# (iv) health

my_health_tot_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("out/", 
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

# (v) combine costenv and health
comb_new <- rbind(my_costenv_tot_dat2, my_health_tot_dat2) %>% 
  arrange(diet_pattern, outcome)

results_10perc <- comb_new %>% 
  select(-c(impact_median, impact_UB, impact_LB)) %>% 
  pivot_wider(id_cols = c(outcome),
              names_from = diet_pattern,
              values_from = starts_with("impact")) %>% 
  select(outcome, ends_with("Med"), ends_with("US"), ends_with("Veg"), ends_with("Vegan"))

# export
write_csv(results_10perc, paste0("tables_figures/manuscript/data/abs_change_10perc_tableau_", export_date, ".csv"))

# prepare manuscript table
write_csv(results_10perc, paste0("tables_figures/manuscript/Table- Absolute change (10% shift).csv"))

# PERCENT CHANGE RESULTS, BY FOOD GROUP -----

a <- comb %>% 
  select(-c(impact_median_day, LB_day, UB_day)) %>% 
  group_by(diet_pattern, outcome) %>% 
  mutate(sum = sum(impact_median_year),
         sum_LB = sum(LB_year),
         sum_UB = sum(UB_year)) %>% 
  arrange(diet_pattern, outcome)

a1 <- a %>% 
  mutate(prop = impact_median_year / sum * 100,
         prop_LB = LB_year / sum_LB * 100,
         prop_UB = UB_year / sum_UB * 100)

# check
a1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(sum(prop),
            sum(prop_LB),
            sum(prop_UB))

# export
write_csv(a1, paste0("tables_figures/manuscript/data/perc_change_byfood_tableau_", export_date, ".csv"))

# PERCENT CHANGE RESULTS, BY POP SUBGROUP -----
# (i) Health -----

my_health_pop_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("out/", 
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
  
  x <- read_csv(paste0("out/", 
                       output_folder_name ,
                       "/cost_env/", 
                       i, 
                       "/per_capita/By_SubGroup/summary.output_by_age_gp_sex_gp_race_gp_Foodgroup.costenv.csv")) %>% 
    select(age_gp, sex_gp, race_gp,
      Foodgroup, outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound_median (97.5th percentile)`,
           current_intake_impact_median,
           `current_intake_impact_lower_bound (2.5th percentile)`,
           `current_intake_impact_upper_bound_median  (97.5th percentile)`,
           CF_intake_impact_median,
           `CF_intake_impact_lower_bound (2.5th percentile)`,
           `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_costenv_pop_list[[i]] <- x
  
}

my_costenv_pop_dat <- bind_rows(my_costenv_pop_list)

# (iii) Forced labor (temporary) -----

my_fl_pop_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("out/output_021524_1000sims_FLonly/cost_env/", 
                       i, 
                       "/per_capita/By_SubGroup/summary.output_by_age_gp_sex_gp_race_gp_Foodgroup.costenv.csv")) %>% 
    select(age_gp, sex_gp, race_gp,
           Foodgroup, outcome, outcome_unit, 
           impact_median,	
           `impact_lower_bound (2.5th percentile)`,
           `impact_upper_bound_median (97.5th percentile)`,
           current_intake_impact_median,
           `current_intake_impact_lower_bound (2.5th percentile)`,
           `current_intake_impact_upper_bound_median  (97.5th percentile)`,
           CF_intake_impact_median,
           `CF_intake_impact_lower_bound (2.5th percentile)`,
           `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_fl_pop_list[[i]] <- x
  
}

my_fl_pop_dat <- bind_rows(my_fl_pop_list)

# (iv) Combine enviro, cost, FL -----

koo <- rbind(my_costenv_pop_dat, my_fl_pop_dat) %>% arrange(diet_pattern, outcome)

koo1 <- koo %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  rename(LB_day = `impact_lower_bound (2.5th percentile)`,
         UB_day = `impact_upper_bound_median (97.5th percentile)`,
         current_intake_impact_LB = `current_intake_impact_lower_bound (2.5th percentile)`,
         current_intake_impact_UB = `current_intake_impact_upper_bound_median  (97.5th percentile)`,
         CF_intake_impact_LB = `CF_intake_impact_lower_bound (2.5th percentile)`,
         CF_intake_impact_UB = `CF_intake_impact_upper_bound_median  (97.5th percentile)`) %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>%
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  relocate(diet_pattern) %>% 
  relocate(outcome, .after = food_group) %>% 
  arrange(diet_pattern, food_group, outcome)

# add per year results
koo2 <- koo1 %>% 
  # select(diet_pattern, food_group, outcome, impact_median, LB_day, UB_day) %>%
  mutate(impact_median_year = impact_median * 365,
         LB_year = LB_day * 365,
         UB_year = UB_day * 365) %>% 
  rename(impact_median_day = impact_median)

# calculate percent change at the pattern-level
koo3 <- koo2 %>% 
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

koo4 <- koo3 %>% 
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
new <- rbind(koo4, h3)

# export
write_csv(new, paste0("tables_figures/manuscript/data/perc_change_bysubgroup_tableau_", export_date, ".csv"))


