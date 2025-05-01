# CREATE RESULTS TABLE 

rm(list = ls())

library(tidyverse)

options(scipen=999)

# Import output data

folder_name <- c("US_diet_both", "Med_diet_both", "Veg_diet_both", "Vegan_diet_both")

my_list <- list()

# i <- "US_diet_both"

for (i in folder_name) {
  
  x <- read_csv(paste0("out/output_101823_1000sims/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv"))

  x1 <- x %>% 
    select(Foodgroup, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`) %>% 
    rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
           impact_UP = `impact_upper_bound_median (97.5th percentile)`) %>% 
    mutate(diet_pattern = i)
  
  my_list[[i]] <- x1
  
  }

dat <- bind_rows(my_list) %>% relocate(diet_pattern)

# transform to wide format

dat_wide <- pivot_wider(dat,
            id_cols = c("diet_pattern", "Foodgroup"),
            names_from = outcome,
            values_from = impact_median) %>% 
  arrange(Foodgroup) 

dat_wide1 <- dat_wide %>% 
  mutate(diet_pattern = sub("_.*", "", diet_pattern)) %>% 
  rename(food = Foodgroup) %>% 
  relocate(Food_price, .after = "WATER")

# export as csv file

write_csv(dat_wide1, "manuscript_code/tables/Outcomes_by_dietpattern_foodgroup_103023.csv")

# extra wide results

food_list <- dat_wide1 %>% select(food) %>% distinct() %>% unlist() %>% as.vector()

dat_wide_wide <- dat_wide1 %>% 
  pivot_wider(id_cols = diet_pattern,
              names_from = food,
              values_from = c(BLUEWATER, CED, GHG, WATER, Food_price))

dat_wide_wide1 <- dat_wide_wide %>% relocate(ends_with("fruit_exc_juice"),
                           ends_with("fruit_juice"),
                           ends_with("veg_dg"),
                           ends_with("veg_ro"),
                           ends_with("veg_sta"),
                           ends_with("veg_oth"),
                           ends_with("gr_whole"),
                           ends_with("gr_refined"),
                           ends_with("dairy"),
                           ends_with("leg_tot"),
                           ends_with("pf_redm"),
                           ends_with("pf_poultry"),
                           ends_with("pf_seafood"),
                           ends_with("pf_egg"),
                           ends_with("pf_ns"),
                           ends_with("leg_tot"),
                           ends_with("sat_fat"),
                           ends_with("sugar"),
                           ends_with("oil"),
                           .after = "diet_pattern")

# export

write_csv(dat_wide_wide1, "manuscript_code/tables/Outcomes_by_dietpattern_foodgroup_wide_103023.csv")
