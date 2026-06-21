rm(list = ls())

library(tidyverse)

# HEALTH -----

health <- read_csv("manuscript_materials/tables/formatted_tables/Table 1.csv")

# calculate my percent
my_perc <- (2525869/244878034)

# calculate 1%
# apply ceiling function to all values
health1 <- health %>% 
  mutate(across(medians_CDP:UB_VEG, ~ ceiling(.x * my_perc)))

# export
write_csv(health1, "manuscript_materials/tables/formatted_tables/Policy shift results - health.csv")

# ENV/COST/SOC -----

env <- read_csv("manuscript_materials/tables/formatted_tables/Table 2 (annual per capita).csv")

# multiply by number of people
env1 <- env %>% 
  select(starts_with(c("outcome", "total"))) %>% 
  rowwise() %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ ceiling(.x * 2525869)))


env2 <- env1 %>% 
  # remove water use
  filter(outcome != "BLUEWATER") %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ if (outcome == "Food_price") round(.x / 1000000000, digits = 1) else .x)) %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ if (outcome == "GHG") round(.x / 1000, digits = 1) else .x)) %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ if (outcome == "CED") round(.x / 1000000000, digits = 1) else .x)) %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ if (outcome == "WATER") round(.x / 1000000000, digits = 1) else .x)) %>% 
  mutate(across(total_impact_median_CDP:total_impact_UB_VEG, ~ if (outcome == "FL") round(.x / 1000000, digits = 1) else .x)) %>% 
  mutate(outcome_unit_new = case_match(outcome_unit,
                                       "USD" ~ "billion USD",
                                       "kgCO2-eq" ~ "tonnes CO2-eq",
                                       "MJ" ~ "billion MJ",
                                       "L-eq" ~ "billion L-eq",
                                       "mrh-eq" ~ "million mrh-eq")) %>% 
  relocate(outcome_unit_new, .after = outcome_unit)
  
# export
write_csv(env2, "manuscript_materials/tables/formatted_tables/Policy shift results - enviro.csv")

