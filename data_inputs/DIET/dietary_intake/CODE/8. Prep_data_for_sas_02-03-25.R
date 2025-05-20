# Prep data for SAS, to use the NCI Method to calculate standard deviations
# Author: Brooke Bell
# Date: 06-26-24

rm(list = ls())

library(tidyverse)
library(fastDummies)

# Import data
nhanes <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_adj_clean_long.rds")

# NEED TO USE ADJUSTED VALUES!!!!! 2-20-24

# only select certain variables
nhanes1 <- nhanes %>% 
  select(SEQN, age, sex, race, subgroup, DRDINT, SDMVPSU, SDMVSTRA, wtnew, reliable_yes, inAnalysis, day, ends_with("adj"))

# create subgroup*inanalysis variable
nhanes2 <- nhanes1 %>% 
  mutate(subgroup_new = ifelse(inAnalysis == "TRUE", subgroup, NA)) %>% 
  relocate(subgroup_new, .after = subgroup)

#check
nhanes2 %>% filter(!(is.na(subgroup)) & !(is.na(subgroup_new))) %>% View()

# create dummy variables
nhanes3 <- nhanes2 %>% 
  dummy_cols(select_columns = c("day", "inAnalysis", "subgroup", "subgroup_new"),
             remove_first_dummy = TRUE)

# select vars
nhanes4 <- nhanes3 %>% 
  # select(SEQN, SDMVPSU, SDMVSTRA, wtnew, day:day_2, starts_with("subgroup_new")) %>% 
  relocate(day_2, .after = day)

# need to remove rows where no diet intake on day 2
nhanes4 %>% filter(DRDINT == 1 & day == 2) %>% View()

nhanes5 <- nhanes4 %>% 
  filter(!(DRDINT == 1 & day == 2))
  
# check
nhanes5 %>% filter(is.na(fruit_tot_adj)) %>% View() #good
nhanes5 %>% filter(is.na(fruit_tot_adj) & inAnalysis == "TRUE") %>% View() #good

# export
write_csv(nhanes5,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes_incl_ssb_adj_clean_long.csv",
          na = "")

write_csv(nhanes5,
          "/Users/bmb73/Documents/GitHub/LASTING/Standard_deviations_new/in/nhanes_incl_ssb_adj_clean_long.csv",
          na = "")
