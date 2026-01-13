# Percent change results, by food group (Figure 2)

rm(list = ls())

library(tidyverse)
library(stringr)
options(scipen=999)

# create vectors
output_folder_name <- "output_032025_1000sims"
cra_folder_name <- dir(paste0("outputs/model/", output_folder_name, "/CRA"))
costenv_folder_name <- dir(paste0("outputs/model/", output_folder_name, "/cost_env"))
costenv_both_folder_name <- costenv_folder_name %>% str_subset(pattern = "both")

# today's date
export_date <- "062625"

# (i) Health -----

# import 2018 cancer/cvd numbers
cancer <- read_csv("data_inputs/FINAL/cleaned_raw_data/cancer_incidence_2025-03-11_FINAL.csv")
cvd <- read_csv("data_inputs/FINAL/cleaned_raw_data/cvd_mortality_2025-03-11_FINAL.csv")

my_health_pop_list <- list()

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
  group_by(diet_pattern, outcome, food_group) %>% 
  summarise(impact_median_year = ceiling(sum(impact_median_year)))

cancer_sub <- cancer %>% 
  filter(diseases != "ALL") %>% 
  summarise(count = sum(count)) %>% 
  # select(count) %>% 
  mutate(outcome = "Cancer (cases)") %>% 
  relocate(outcome, .before = count)

cvd_sub <- cvd %>% 
  select(-c(TSTK, subgroup, contains(c("se_", "medBMI", "medSBP")))) %>% 
  rowwise() %>% 
  mutate(count = sum(c_across(AA:RHD))) %>%
  select(Age, Sex, Race, count) %>% 
  ungroup() %>% 
  summarise(count = sum(count)) %>% 
  mutate(outcome = "CVD (deaths)") %>% 
  relocate(outcome, .before = count)

disease_comb <- rbind(cancer_sub, cvd_sub) %>% 
  arrange(outcome)

h1 <- left_join(h, disease_comb, by = c("outcome"))

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

# calculate percent change at the pattern-level
my_costenv_pop_dat2 <- my_costenv_pop_dat1 %>% 
  group_by(diet_pattern, outcome, food_group) %>% 
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
write_csv(my_costenv_pop_dat2, paste0("manuscript_materials/figures/tableau_data/perc_change_byfood_temp_", export_date, ".csv"))


my_costenv_pop_dat3 <- my_costenv_pop_dat2 %>% 
  select(diet_pattern, outcome, food_group, starts_with("perc_change"))

h3 <- h2 %>% 
  select(diet_pattern, outcome, food_group, perc_change) %>% 
  mutate(perc_change_LB = NA,
         perc_change_UB = NA) %>% 
  ungroup()

# merge health and others
new <- rbind(my_costenv_pop_dat3, h3)

# fix negative UIs
new1 <- new %>% 
  mutate(perc_change_UB_new = ifelse(perc_change < 0, perc_change_LB, perc_change_UB),
         perc_change_LB_new = ifelse(perc_change < 0, perc_change_UB, perc_change_LB))

# export
write_csv(new1, paste0("manuscript_materials/figures/tableau_data/perc_change_byfood_tableau_", export_date, ".csv"))
write_csv(new1, "manuscript_materials/figures/tableau_data/perc_change_byfood_tableau_final.csv")


