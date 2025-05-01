# CREATE RESULTS TABLES

rm(list = ls())

library(tidyverse)

options(scipen=999)

# Import output data

costenv_folder_name <- c("US_diet_both", "Med_diet_both", "Veg_diet_both", "Vegan_diet_both")

cra_folder_name <- c("US", "Med", "Veg", "Vegan")

# RESULTS BY FOOD GROUP -----

my_list <- list()

for (i in costenv_folder_name) {
  
  x <- read_csv(paste0("out/output_111423_100sims/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv"))

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

# RESULTS BY AGE/SEX/RACE -----

# debug
# z <- "age_gp"

temp_func <- function(z){
  
  my_list <- list()
  
  for (i in costenv_folder_name) {
    
    x <- read_csv(paste0("out/output_111423_100sims/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_", z, ".costenv.csv"))
    
    x1 <- x %>% 
      select(z, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`) %>% 
      rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
             impact_UP = `impact_upper_bound_median (97.5th percentile)`) %>% 
      mutate(diet_pattern = i)
    
    my_list[[i]] <- x1
  }
  
  my_dat <- bind_rows(my_list) %>% relocate(diet_pattern)
  
  # transform to wide format
  my_dat_wide <- pivot_wider(my_dat,
                             id_cols = c("diet_pattern", z),
                             names_from = outcome,
                             values_from = impact_median) %>% 
    arrange(diet_pattern, z) 
  
  # fix names
  my_dat_wide1 <- my_dat_wide %>% 
    mutate(diet_pattern = sub("_.*", "", diet_pattern)) %>% 
    # rename(food = Foodgroup) %>% 
    relocate(Food_price, .after = "WATER")
  
  # export as csv file
  write_csv(my_dat_wide1, paste0("manuscript_code/tables/Outcomes_by_dietpattern_", z, "_111423.csv"))
  
}

# AGE
temp_func("age_gp")

# SEX
temp_func("sex_gp")

# RACE
temp_func("race_gp")


# RESULTS BY FOOD GROUP, BY AGE/SEX/RACE -----

# write function

# debug
# z <- "age_gp"

subgroup_tables <- function(z){
  
  my_list <- list()
  
  for (i in costenv_folder_name) {
    
    x <- read_csv(paste0("out/output_111423_100sims/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_", z, "_Foodgroup.costenv.csv"))
    
    x1 <- x %>% 
      select(z, Foodgroup, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`) %>% 
      rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
             impact_UP = `impact_upper_bound_median (97.5th percentile)`) %>% 
      mutate(diet_pattern = i)
    
    my_list[[i]] <- x1
  }
  
  my_dat <- bind_rows(my_list) %>% relocate(diet_pattern)
  
  # transform to wide format
  my_dat_wide <- pivot_wider(my_dat,
                             id_cols = c("diet_pattern", z, "Foodgroup"),
                             names_from = outcome,
                             values_from = impact_median) %>% 
    arrange(Foodgroup, diet_pattern, z) 
  
  # fix names
  my_dat_wide1 <- my_dat_wide %>% 
    mutate(diet_pattern = sub("_.*", "", diet_pattern)) %>% 
    rename(food = Foodgroup) %>% 
    relocate(Food_price, .after = "WATER")
  
  # export as csv file
  write_csv(my_dat_wide1, paste0("manuscript_code/tables/Outcomes_by_dietpattern_foodgroup_", z, "_111423.csv"))
  
}


# AGE
subgroup_tables(z="age_gp")

# RACE
subgroup_tables(z="race_gp")

# SEX
subgroup_tables(z="sex_gp")


