# Calculate price at food level
# Author: Brooke Bell
# Date: 7-27-23

rm(list = ls())

library(tidyverse)
library(readxl)
library(survey)

# IMPORT DATA -----

# first, read in nhanes food-level data

day1 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day1_clean.rds")

day1_sub <- day1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DR1IGRMS, DESCRIPTION, nhanes_cycle) %>% 
  mutate(nhanes1516 = ifelse(nhanes_cycle == "2015-2016", 1, 0)) %>% 
  rename("foodcode" = "DR1IFDCD")

day2 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day2_clean.rds")

day2_sub <- day2 %>% 
  select(SEQN, DR2ILINE, DR2IFDCD, DR2IGRMS, DESCRIPTION, nhanes_cycle) %>% 
  mutate(nhanes1516 = ifelse(nhanes_cycle == "2015-2016", 1, 0)) %>% 
  rename("foodcode" = "DR2IFDCD")


#rm(day1, day2)

# import 
cost1516 <- read_xlsx("in/Food prices (Brooke)/raw data/pp_national_average_prices_andi_v.1.30.2023.xlsx",
                      sheet = "PP-NAP1516") %>% 
  select(food_code, price_100gm) %>% 
  mutate(nhanes1516 = 1)

cost1718 <- read_xlsx("in/Food prices (Brooke)/raw data/pp_national_average_prices_andi_v.1.30.2023.xlsx",
                      sheet = "PP-NAP1718") %>% 
  select(food_code, price_100gm) %>% 
  mutate(nhanes1516 = 0)

price_comb <- rbind(cost1516, cost1718) %>% mutate(price_per_gram = price_100gm / 100)


# combine with food data
day1_map <- left_join(day1_sub, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
  mutate(foodcode = as.character(foodcode))

day2_map <- left_join(day2_sub, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
  mutate(foodcode = as.character(foodcode))

# Create FNDDS to dietary factor mapping
day1_map1 <-
  day1_map %>% 
  mutate(food_group = case_when(substr(foodcode, 1, 1) == "1" ~ "dairy",
                                substr(foodcode, 1, 2) == "20" | substr(foodcode, 1, 2) == "21" | substr(foodcode, 1, 2) == "22" | substr(foodcode, 1, 2) == "23" ~ "pf_redm",
                                substr(foodcode, 1, 2) == "24" ~ "pf_poultry",
                                substr(foodcode, 1, 2) == "25" ~ "pf_pm",
                                substr(foodcode, 1, 2) == "26" ~ "pf_seafood",
                                substr(foodcode, 1, 2) == "31" ~ "pf_egg",
                                substr(foodcode, 1, 2) == "41" ~ "leg_tot",
                                substr(foodcode, 1, 2) == "42" | substr(foodcode, 1, 2) == "43" | substr(foodcode, 1, 2) == "44" ~ "pf_ns",
                                substr(foodcode, 1, 2) == "50" | substr(foodcode, 1, 2) == "51" | substr(foodcode, 1, 2) == "52" | substr(foodcode, 1, 2) == "53" | substr(foodcode, 1, 2) == "54" | substr(foodcode, 1, 2) == "55" | substr(foodcode, 1, 2) == "56" | substr(foodcode, 1, 2) == "57" ~ "gr_total",
                                substr(foodcode, 1, 2) == "81" ~ "sat_fat",
                                substr(foodcode, 1, 2) == "82" ~ "oil",
                                substr(foodcode, 1, 2) == "91" ~ "added_sugar",
                                substr(foodcode, 1, 2) == "92" ~ "ssb",
                                substr(foodcode, 1, 3) == "611" | substr(foodcode, 1, 2) == "62" | substr(foodcode, 1, 2) == "63" ~ "fruit_exc_juice",
                                substr(foodcode, 1, 2) == "64" | substr(foodcode, 1, 3) == "612" ~ "fruit_juice",
                                substr(foodcode, 1, 2) == "71" ~ "veg_sta",
                                substr(foodcode, 1, 2) == "72" ~ "veg_dg",
                                substr(foodcode, 1, 2) == "73" | substr(foodcode, 1, 2) == "74" ~ "veg_ro",
                                substr(foodcode, 1, 2) == "75" ~ "veg_oth"),
         fndds_price = DR1IGRMS * price_per_gram) 

day2_map1 <-
  day2_map %>% 
  mutate(food_group = case_when(substr(foodcode, 1, 1) == "1" ~ "dairy",
                                substr(foodcode, 1, 2) == "20" | substr(foodcode, 1, 2) == "21" | substr(foodcode, 1, 2) == "22" | substr(foodcode, 1, 2) == "23" ~ "pf_redm",
                                substr(foodcode, 1, 2) == "24" ~ "pf_poultry",
                                substr(foodcode, 1, 2) == "25" ~ "pf_pm",
                                substr(foodcode, 1, 2) == "26" ~ "pf_seafood",
                                substr(foodcode, 1, 2) == "31" ~ "pf_egg",
                                substr(foodcode, 1, 2) == "41" ~ "leg_tot",
                                substr(foodcode, 1, 2) == "42" | substr(foodcode, 1, 2) == "43" | substr(foodcode, 1, 2) == "44" ~ "pf_ns",
                                substr(foodcode, 1, 2) == "50" | substr(foodcode, 1, 2) == "51" | substr(foodcode, 1, 2) == "52" | substr(foodcode, 1, 2) == "53" | substr(foodcode, 1, 2) == "54" | substr(foodcode, 1, 2) == "55" | substr(foodcode, 1, 2) == "56" | substr(foodcode, 1, 2) == "57" ~ "gr_total",
                                substr(foodcode, 1, 2) == "81" ~ "sat_fat",
                                substr(foodcode, 1, 2) == "82" ~ "oil",
                                substr(foodcode, 1, 2) == "91" ~ "added_sugar",
                                substr(foodcode, 1, 2) == "92" ~ "ssb",
                                substr(foodcode, 1, 3) == "611" | substr(foodcode, 1, 2) == "62" | substr(foodcode, 1, 2) == "63" ~ "fruit_exc_juice",
                                substr(foodcode, 1, 2) == "64" | substr(foodcode, 1, 3) == "612" ~ "fruit_juice",
                                substr(foodcode, 1, 2) == "71" ~ "veg_sta",
                                substr(foodcode, 1, 2) == "72" ~ "veg_dg",
                                substr(foodcode, 1, 2) == "73" | substr(foodcode, 1, 2) == "74" ~ "veg_ro",
                                substr(foodcode, 1, 2) == "75" ~ "veg_oth"),
         fndds_price = DR2IGRMS * price_per_gram) 

# export these datasets
write_csv(day1_map1, "in/Environmental impact (Brooke)/clean data/Cost_by_fnddscode_day1_07272023.csv")
write_csv(day2_map1, "in/Environmental impact (Brooke)/clean data/Cost_by_fnddscode_day2_07272023.csv")

# sum the impact per person, per dietary factor
day1_sum_impact <- day1_map1 %>% 
  group_by(SEQN, food_group) %>% 
  summarise(price_sum_day1 = sum(fndds_price)) %>% 
  filter(!(is.na(food_group))) %>% 
  replace(is.na(.), 0)

day2_sum_impact <- day2_map1 %>% 
  group_by(SEQN, food_group) %>% 
  summarise(price_sum_day2 = sum(fndds_price)) %>% 
  filter(!(is.na(food_group))) %>% 
  replace(is.na(.), 0)

# full join
sum_impact <- full_join(day1_sum_impact, day2_sum_impact)

sum_impact1 <- sum_impact %>% 
  rowwise() %>% 
  mutate(price_avg = mean(c(price_sum_day1, price_sum_day2), na.rm = TRUE))

# export
write_csv(sum_impact1, "in/Environmental impact (Brooke)/clean data/Cost_by_person_07272023.csv")


# transform to wide
sum_impact_wide <- sum_impact1 %>% pivot_wider(id_cols = SEQN,
                                              names_from = food_group,
                                              values_from = price_avg) %>% 
  replace(is.na(.), 0) # might need to move this earlier

# CALCULATE COST, BY FOOD, BY SUBGROUP -----

# import subgroup-seqn mapping
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

# join
sum_impact_wide1 <- left_join(sum_impact_wide, subgroup_dat, by = "SEQN")

# Define survey design for cost dataset 
my_svy_cost <- svydesign(data=sum_impact_wide1, 
                        id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                        strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                        weights=~wtnew, # New sample weight
                        nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_cost_sub <- subset(my_svy_cost, inAnalysis==1)

# CALCULATE COST 

allfoods_cost_bysub <- svyby(~gr_total+
                              #gr_refined+
                              #gr_whole+
                              dairy+
                              fruit_exc_juice+ 
                              fruit_juice+
                              veg_dg+
                              veg_oth+
                              veg_ro+
                              veg_sta+
                              pf_ns+
                              pf_egg+
                              pf_poultry+
                              pf_redm+
                              pf_seafood+
                              leg_tot+
                              added_sugar+
                              #coffee_tea+
                              oil+
                              sat_fat,
                              #other+
                              #water,
                            ~subgroup, 
                            my_svy_cost_sub, 
                            svymean)

# Reformat unadjusted output to match model data
my_se_cost <- allfoods_cost_bysub %>% select(subgroup, starts_with("se."))

my_mean_cost <- allfoods_cost_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_cost_long <- my_se_cost %>% pivot_longer(cols = starts_with("se."),
                                             names_to = "food",
                                             names_prefix = "se.",
                                             values_to = "cost_se")

my_mean_cost_long <- my_mean_cost %>% pivot_longer(cols = !subgroup,
                                                 names_to = "food",
                                                 values_to = "cost_mean")

# combine
allfoods_cost_bysub_long <- 
  left_join(my_mean_cost_long, my_se_cost_long, by = c("subgroup", "food")) %>% 
  arrange(food, subgroup)

# export
write_csv(allfoods_cost_bysub_long, "in/Environmental impact (Brooke)/clean data/Cost_by_subgroup_07272023.csv")



