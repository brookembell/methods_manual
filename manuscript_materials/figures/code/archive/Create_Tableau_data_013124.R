# Create data for Tableau
# 01-31-24

# SET UP -----

rm(list = ls())
library(tidyverse)
library(stringr)
options(scipen=999)

# create vectors
output_folder_name <- "output_013124_1000sims"
cra_folder_name <- dir(paste0("out/", output_folder_name, "/CRA"))
costenv_folder_name <- dir(paste0("out/", output_folder_name, "/cost_env"))

export_date <- "020124"

# HEALTH RESULTS -----

my_health_list <- list()

for (i in cra_folder_name) {
  
  x <- read_csv(paste0("out/", 
                       output_folder_name ,
                       "/CRA/", 
                       i, 
                       "/summarystats_attributable_USmortality_by_age_female_race_pathway_disease_type2_2015_",
                       i,
                       ".csv")) %>% 
    select(age, female, race, pathway, disease_type2, riskfactor, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern)
  
  my_health_list[[i]] <- x
  
}

my_health_dat <- bind_rows(my_health_list)

# need to merge subgroup #s and disease type category

# # diseases
# diseases <- read_csv("in/FINAL/pre_data/disease_outcomes_060923_FINAL.csv") %>% 
#   select(disease_group, outcome)
# 
# my_health_dat1 <- left_join(my_health_dat, diseases, by = "outcome") %>% 
#   relocate(disease_group, .before = outcome)

# subgroups
pop <- read_csv("in/FINAL/pre_data/population_subgroups_48_060923_FINAL.csv")

# table(my_health_dat1$age)
# table(my_health_dat1$female)
# table(my_health_dat1$race)

my_health_dat1 <- my_health_dat %>% 
  mutate(Age = case_when(age == "25" ~ 1,
                         age == "35" ~ 2,
                         age == "45" ~ 3,
                         age == "55" ~ 4,
                         age == "65" ~ 5,
                         age == "75" ~ 6),
         Sex = case_when(female == 1 ~ 1,
                         female == 0 ~ 2)) %>% 
  rename(Race = race)

my_health_dat2 <- my_health_dat1 %>% 
  left_join(pop, by = c("Age", "Sex", "Race")) %>% 
  select(-c(age, female, Age, Sex, Race)) %>% 
  relocate(subgroup, .after = diet_pattern) %>% 
  relocate(Age_label, Sex_label, Race_label, .after = subgroup) %>% 
  relocate(riskfactor, .after = Race_label) %>% 
  rename(food_group = riskfactor,
         median = medians,
         median_UB = UB,
         median_LB = LB,
         disease = disease_type2) %>% 
  relocate(disease, .before = pathway) %>% 
  arrange(diet_pattern, subgroup, food_group, disease, pathway) 


# COST/ENVIRO RESULTS -----

my_costenv_list <- list()

# debug
# i="Med_diet_both"
# i="Med_diet_Gro"

for (i in costenv_folder_name) {
  
  if(grepl("_both", i)){
    
    x <- read_csv(paste0("out/", 
                         output_folder_name ,
                         "/cost_env/", 
                         i, 
                         "/per_capita/By_SubGroup/summary.output_by_age_gp_sex_gp_race_gp_Foodgroup.costenv.csv")) %>% 
      select(age_gp, sex_gp, race_gp, Foodgroup, outcome, outcome_unit, 
             # `impact_lower_bound (2.5th percentile)`,	
             impact_median,	
             # `impact_upper_bound_median (97.5th percentile)`,
             current_intake_impact_median,
             CF_intake_impact_median
             ) %>% 
      # rename(impact_UB = `impact_upper_bound_median (97.5th percentile)`)
      mutate(diet_pattern = paste0(i)) %>% 
      relocate(diet_pattern)
    
  } else {
    
    x <- read_csv(paste0("out/", 
                         output_folder_name ,
                         "/cost_env/", 
                         i, 
                         "/per_capita/By_SubGroup/summary.output.percapita_by_age_gp_sex_gp_race_gp_Foodgroup.costenv.csv")) %>% 
      select(age_gp, sex_gp, race_gp, Foodgroup, outcome, outcome_unit, 
             # `impact_lower_bound (2.5th percentile)`,	
             `impact_median`,	
             # `impact_upper_bound  (97.5th percentile)`
             current_intake_impact_median,
             CF_intake_impact_median
             ) %>% 
      # rename(impact_UB = `impact_upper_bound  (97.5th percentile)`)
      mutate(diet_pattern = paste0(i)) %>% 
      relocate(diet_pattern)
    
  }
  
  my_costenv_list[[i]] <- x
  
}

my_costenv_dat <- bind_rows(my_costenv_list)

# fix upper bound variable

my_costenv_dat1 <- my_costenv_dat %>% 
  # mutate(impact_UB = ifelse(is.na(`impact_upper_bound  (97.5th percentile)`), `impact_upper_bound_median (97.5th percentile)`, `impact_upper_bound  (97.5th percentile)`)) %>% 
  # rename(impact_LB = `impact_lower_bound (2.5th percentile)`) %>% 
  arrange(diet_pattern) %>% 
  # select(-c(`impact_upper_bound_median (97.5th percentile)`, `impact_upper_bound  (97.5th percentile)`)) %>% 
  mutate(outcome_new = paste0(outcome, " (", outcome_unit, ")"))

my_costenv_dat2 <- my_costenv_dat1 %>% 
  mutate(diet_pattern_new = str_extract(diet_pattern, "[^_]+"),
         cost_type = case_when(grepl("_both", diet_pattern) ~ "Total",
                               grepl("_Gro", diet_pattern) ~ "Grocery",
                               grepl("_Oth", diet_pattern) ~ "Non-Grocery"))

# fix subgroups

my_costenv_dat3 <- left_join(my_costenv_dat2, pop, by = c("age_gp" = "Age_label",
                                                          "race_gp" = "Race_label",
                                                          "sex_gp" = "Sex_label"))

my_costenv_dat4 <- my_costenv_dat3 %>% 
  select(-c(diet_pattern, outcome, outcome_unit, Age, Sex, Race)) %>% 
  rename(diet_pattern = diet_pattern_new,
         Age_label = age_gp,
         Race_label = race_gp,
         Sex_label = sex_gp,
         outcome = outcome_new) %>% 
  relocate(diet_pattern, subgroup) %>% 
  relocate(cost_type, .after = Foodgroup) %>% 
  relocate(outcome, .before = cost_type) %>% 
  rename(food_group = Foodgroup,
         median_diff = impact_median,
         # median_LB = impact_LB,
         # median_UB = impact_UB
         median_CF = CF_intake_impact_median,
         median_current = current_intake_impact_median) %>% 
  # relocate(median_diff, median_CF, median_current, .before = median_LB) %>% 
  rowwise() %>% 
  mutate(perc_diff = ((median_CF - median_current)/median_current)*100) %>% 
  arrange(diet_pattern, subgroup, food_group, outcome, cost_type) %>% 
  # remove dga+ for now
  filter(diet_pattern != "DGAplus")

my_costenv_dat4 %>% filter(cost_type == "Total") %>% View()

# group by diet pattern

costenv_pivot <- my_costenv_dat4 %>% 
  group_by(diet_pattern, food_group, outcome, cost_type) %>% 
  summarise(mean_perc_diff = mean(perc_diff)) %>% 
  filter(cost_type == "Total" & outcome == "CED (mJ)") %>% 
  filter(mean_perc_diff != "NaN") %>% 
  ungroup() %>% 
  select(-c(cost_type, outcome))

# EXPORT -----

write_csv(my_health_dat2, paste0("tables_figures/clean_data/health_data_clean_tableau_", export_date, ".csv"))
write_csv(my_costenv_dat4, paste0("tables_figures/clean_data/costenv_data_clean_tableau_", export_date, ".csv"))

write_csv(costenv_pivot, paste0("tables_figures/clean_data/costenv_pivot_tableau_", export_date, ".csv"))


