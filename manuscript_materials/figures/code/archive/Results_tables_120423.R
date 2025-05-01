# CREATE RESULTS TABLES
# Author: Brooke Bell
# Date: 12-04-23

# set up

rm(list = ls())

library(tidyverse)

options(scipen=999)

# create vectors

output_folder_name <- "output_111623_1000sims"

costenv_folder_name <- c("US_diet_both", "Med_diet_both", "Veg_diet_both", "Vegan_diet_both")

cra_folder_name <- c("US", "Med", "Veg", "Vegan")

export_date <- "120423"

# COSTENV RESULTS FUNCTION -----

# debug
# z <- "all"
# i="US_diet_both"

costenv_results <- function(z){
  
  my_list <- list()
  
  for (i in costenv_folder_name) {
    
    x <- read_csv(paste0("out/", output_folder_name ,"/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_", z, ".costenv.csv"))
    
    # ifelse statement  
      if(z=="all"){
        
        x1 <- x %>% select(outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`)
        
      } else {
        
        x1 <- x %>% select(z, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`)
        
      }

      x2 <- x1  %>% 
      rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
             impact_UP = `impact_upper_bound_median (97.5th percentile)`) %>% 
      mutate(diet_pattern = i)
    
    my_list[[i]] <- x2
  }
  
  my_dat <- bind_rows(my_list) %>% relocate(diet_pattern)
  
  # transform to wide format
  
  if(z=="all"){
    
  my_dat_wide <- pivot_wider(my_dat,
                             id_cols = c("diet_pattern"),
                             names_from = outcome,
                             values_from = impact_median) %>% 
    arrange(diet_pattern) 
  
  } else {
    
    my_dat_wide <- pivot_wider(my_dat,
                               id_cols = c("diet_pattern", z),
                               names_from = outcome,
                               values_from = impact_median) %>% 
      arrange(diet_pattern, z) 
    
  }
  
  # fix names
  my_dat_wide1 <- my_dat_wide %>% 
    mutate(diet_pattern = sub("_.*", "", diet_pattern)) %>% 
    # rename(food = Foodgroup) %>% 
    relocate(Food_price, .after = "WATER")
  
  # export as csv file
  write_csv(my_dat_wide1, paste0("manuscript_code/tables/Outcomes_by_dietpattern_", z, "_", export_date, ".csv"))
  
}

costenv_results(z="all")
costenv_results(z="age_gp")
costenv_results(z="sex_gp")
costenv_results(z="race_gp")

# RESULTS BY FOOD GROUP -----

# debug
# z <- "all"
# i="US_diet_both"

costenv_results_food <- function(z){
  
  my_list <- list()
  
  for (i in costenv_folder_name) {
    
    if(z=="all"){
      
      x <- read_csv(paste0("out/", output_folder_name ,"/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_Foodgroup.costenv.csv")) %>% 
        select(Foodgroup, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`)
      
    } else {
      
      x <- read_csv(paste0("out/", output_folder_name ,"/cost_env/", i, "/per_capita/By_SubGroup/summary.output_by_", z, "_Foodgroup.costenv.csv")) %>% 
        select(z, Foodgroup, outcome, outcome_unit, `impact_lower_bound (2.5th percentile)`, impact_median, `impact_upper_bound_median (97.5th percentile)`)

    }
    
    x1 <- x  %>% 
      rename(impact_LB = `impact_lower_bound (2.5th percentile)`,
             impact_UP = `impact_upper_bound_median (97.5th percentile)`) %>% 
      mutate(diet_pattern = i)
    
    my_list[[i]] <- x1
  }
  
  my_dat <- bind_rows(my_list) %>% relocate(diet_pattern)
  
  # transform to wide format
  
  if(z=="all"){
    
    my_dat_wide <- pivot_wider(my_dat,
                               id_cols = c("diet_pattern", "Foodgroup"),
                               names_from = outcome,
                               values_from = impact_median) %>% 
      arrange(Foodgroup, diet_pattern) 
    
  } else {
    
    my_dat_wide <- pivot_wider(my_dat,
                               id_cols = c("diet_pattern", z, "Foodgroup"),
                               names_from = outcome,
                               values_from = impact_median) %>% 
      arrange(Foodgroup, diet_pattern, z) 
    
  }
  
  # fix names
  my_dat_wide1 <- my_dat_wide %>% 
    mutate(diet_pattern = sub("_.*", "", diet_pattern)) %>% 
    rename(food = Foodgroup) %>%
    relocate(Food_price, .after = "WATER")
  
  # export as csv file
  if(z=="all"){
    
    write_csv(my_dat_wide1, paste0("manuscript_code/tables/Outcomes_by_dietpattern_foodgroup_", export_date, ".csv"))

  } else {
    
    write_csv(my_dat_wide1, paste0("manuscript_code/tables/Outcomes_by_dietpattern_foodgroup_", z, "_", export_date, ".csv"))
    
  }
  
}

costenv_results_food(z="age_gp")
costenv_results_food(z="sex_gp")
costenv_results_food(z="race_gp")
costenv_results_food(z="all")



