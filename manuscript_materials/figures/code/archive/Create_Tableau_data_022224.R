# Create data for Tableau
# 02-22-24

# SET UP -----

rm(list = ls())
library(tidyverse)
library(stringr)
library(gtsummary)
options(scipen=999)

# create vectors
output_folder_name <- "output_013124_1000sims"
cra_folder_name <- dir(paste0("out/", output_folder_name, "/CRA"))
costenv_folder_name <- dir(paste0("out/", output_folder_name, "/cost_env"))
costenv_both_folder_name <- costenv_folder_name %>% str_subset(pattern = "both")

export_date <- "020724"

# ABSOLUTE HEALTH CHANGE RESULTS -----

my_health_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("out/", 
                       output_folder_name ,
                       "/CRA/", 
                       i, 
                       "/summarystats_attributable_USmortality_by_disease_type_2015_",
                       i,
                       ".csv")) %>% 
    select(disease_type, riskfactor, medians) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_health_list[[i]] <- x
  
}

my_health_dat <- bind_rows(my_health_list)

my_health_dat1 <- my_health_dat %>% 
  mutate(disease_type = ifelse(disease_type == "CVD", paste0(disease_type, " (deaths)"), paste0(disease_type, " (cases)"))) %>% 
  rename(outcome = disease_type, 
         food_group = riskfactor,
         impact_median_year = medians) %>% 
  mutate(impact_median_day = NA) %>% 
  relocate(food_group, .after = diet_pattern) %>% 
  arrange(diet_pattern, food_group, outcome)
  

# ABSOLUTE COST/ENVIRO CHANGE RESULTS (PER CAPITA) -----

my_costenv_list <- list()

for (i in costenv_both_folder_name) {
    
    x <- read_csv(paste0("out/", 
                         output_folder_name ,
                         "/cost_env/", 
                         i, 
                         "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv")) %>% 
      select(Foodgroup, outcome, outcome_unit, 
             impact_median,	
             current_intake_impact_median,
             CF_intake_impact_median
             ) %>% 
      mutate(diet_pattern = paste0(i)) %>% 
      relocate(diet_pattern)
  
  my_costenv_list[[i]] <- x
  
}

my_costenv_dat <- bind_rows(my_costenv_list)

my_costenv_dat1 <- my_costenv_dat %>% 
  arrange(diet_pattern) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  select(diet_pattern_new, Foodgroup, outcome_new, impact_median) %>% 
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  arrange(diet_pattern, food_group, outcome)

# add per year results
my_costenv_dat2 <- my_costenv_dat1 %>% 
  mutate(impact_median_year = impact_median * 365) %>% 
  rename(impact_median_day = impact_median)

# combine costenv and health
comb <- rbind(my_costenv_dat2, my_health_dat1) %>% 
  arrange(diet_pattern, food_group, outcome)

# export
write_csv(comb, paste0("tables_figures/clean_data/all_results_by_foodgroup_tableau_", export_date, ".csv"))

# export manuscript table
comb1 <- comb %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(impact = sum(impact_median_year)) %>% 
  mutate(impact = ifelse(outcome == "Cancer (cases)" | outcome == "CVD (deaths)", impact * -1, impact))

comb2 <- comb1 %>% 
  pivot_wider(names_from = diet_pattern,
              values_from = impact)

comb3 <- comb2 %>% mutate(across(where(is.numeric), round, 0))

write_csv(comb3, "tables_figures/manuscript/Table- Absolute change.csv")

# PERCENT CHANGE COST/ENV RESULTS -----

# cost/env first
costenv1 <- my_costenv_dat %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"),
         diet_pattern_new = str_extract(diet_pattern, "[^_]+")) %>% 
  select(-c(diet_pattern, outcome, outcome_unit)) %>% 
  rename(diet_pattern = diet_pattern_new,
         food_group = Foodgroup,
         outcome = outcome_new) %>% 
  relocate(diet_pattern) %>% 
  relocate(outcome, .after = food_group) %>% 
  arrange(diet_pattern, food_group, outcome)

# pattern-level
costenv3 <- costenv1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(total_impact_current = sum(current_intake_impact_median),
            total_impact_CF = sum(CF_intake_impact_median)) %>% 
  mutate(perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100) %>% 
  arrange(outcome)

costenv4 <- costenv3 %>% 
  select(diet_pattern, outcome, perc_change)

# export (costenv only)
# write_csv(costenv4, paste0("tables_figures/clean_data/costenv_results_percchange_tableau_", export_date, ".csv"))

# now heatlh
health1 <- my_health_dat1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(total_impact_shift = sum(impact_median_year))

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
health2 <- health1 %>% 
  rowwise() %>% 
  mutate(total_impact_current = ifelse(outcome == "Cancer (cases)", cancer1, cvd1),
         total_impact_CF = total_impact_current - total_impact_shift,
         perc_change = ((total_impact_CF - total_impact_current) / total_impact_current) * 100)



health3 <- health2 %>% 
  select(diet_pattern, outcome, perc_change)

# combine costenv and health
all <- rbind(costenv4, health3) %>% arrange(outcome)

# export
write_csv(all, paste0("tables_figures/clean_data/all_results_percchange_tableau_", export_date, ".csv"))

# PROPORTION CHANGE RESULTS -----

ghg_prop <- my_costenv_dat1 %>% 
  filter(outcome == "GHG (kgCO2eq)") %>% 
  group_by(diet_pattern) %>% 
  mutate(impact_sum = sum(impact_median),
         prop = (impact_median / impact_sum) *100)

ghg_prop %>% group_by(diet_pattern) %>% summarise(sum(prop))

# export
write_csv(ghg_prop, paste0("tables_figures/clean_data/costenv_results_proportion_by_foodgroup_tableau_", export_date, ".csv"))

# PROPORTION (NO SHIFT) RESULTS -----

# NEED TO CHANGE ALL UNITS INTO GRAMS!!!!

x <- read_csv("Impact factor review/data/impact_factors_consumption_with_waste.csv") %>% 
  filter(food != "Total")

x1 <- x %>% select(food, current, US, Med, Vegetarian, Vegan, ends_with(c("_current", "_US", "_Med", "_Vegetarian", "_Vegan")))

x2 <- pivot_longer(x1, cols = !food,
                   names_to = "var",
                   values_to = "value")

x3 <- x2 %>% mutate(dietary_pattern = case_when(grepl("US", var) ~ "US",
                                                grepl("Med", var) ~ "Med",
                                                grepl("Vegetarian", var) ~ "Vegetarian",
                                                grepl("Vegan", var) ~ "Vegan",
                                                grepl("current", var) ~ "Current"),
                    outcome = case_when(grepl("GHG", var) ~ "GHG",
                                        grepl("CED", var) ~ "CED",
                                        grepl("^WATER", var) ~ "Water",
                                        grepl("BLUEWATER", var) ~ "Bluewater",
                                        TRUE ~ "Intake")) %>% 
  select(-var)

x4 <- x3 %>% 
  relocate(dietary_pattern, food, outcome) %>% 
  arrange(dietary_pattern, food, outcome)

x5 <- x4 %>% 
  group_by(dietary_pattern, outcome) %>% 
  mutate(sum = sum(value),
         prop = (value/sum)*100) %>% 
  arrange(dietary_pattern, outcome)

x5 %>% group_by(dietary_pattern, outcome) %>% summarise(sum(prop)) #good

# export
write_csv(x5, paste0("tables_figures/clean_data/intake_proportion_by_foodgroup_tableau_", export_date, ".csv"))

# ABSOLUTE COST/ENVIRO/HEALTH CHANGE RESULTS (10% SHIFT) -----

# fl (temp)
my_fl_tot_list <- list()

for (i in costenv_both_folder_name) {
  
  x <- read_csv(paste0("out/output_013124_1000sims/cost_env/", 
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


# cost/enviro
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

my_costenv_tot_dat1 <- my_costenv_tot_dat %>% 
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
# health
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

# combine costenv and health
comb_new <- rbind(my_costenv_tot_dat2, my_health_tot_dat2) %>% 
  arrange(diet_pattern, outcome)

results_10perc <- comb_new %>% 
  select(-c(impact_median, impact_UB, impact_LB)) %>% 
  pivot_wider(id_cols = c(outcome),
              names_from = diet_pattern,
              values_from = starts_with("impact"))

# export
write_csv(results_10perc, paste0("tables_figures/clean_data/all_results_10percshift_tableau_", export_date, ".csv"))

# mil <- 1000000
# thou <- 1000
# bil <- 1000000000
# tril <- 1000000000000
# 
# results_10perc %>% filter(outcome == "Cancer (cases)") %>% View()
# results_10perc %>% filter(outcome == "BLUEWATER (L)") %>% mutate_at(vars(!outcome),
#                                                                     .funs = funs((. / bil) %>% round(digits = 2))) %>% View()
# results_10perc %>% filter(outcome == "Food_price ($)") %>% View()
# results_10perc %>% filter(outcome == "GHG (kgCO2eq)") %>% View()
# results_10perc %>% filter(outcome == "CED (mJ)") %>% View()
# results_10perc %>% filter(outcome == "CED (mJ)") %>% mutate_at(vars(!outcome),
#                                                                     .funs = funs((. / bil) %>% round(digits = 2))) %>% View()
# results_10perc %>% filter(outcome == "WATER (litereq)") %>% View()
# results_10perc %>% filter(outcome == "WATER (litereq)") %>% mutate_at(vars(!outcome),
#                                                                .funs = funs((. / tril) %>% round(digits = 1))) %>% View()
# health
my_health_dat1 %>% 
  group_by(diet_pattern, outcome) %>% 
  summarise(sum(impact_median_year))


