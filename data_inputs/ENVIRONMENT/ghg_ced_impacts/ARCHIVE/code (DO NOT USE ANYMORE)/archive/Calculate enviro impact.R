# Calculate environmental impact at food level
# Author: Brooke Bell
# Date: 7-27-23

rm(list = ls())

library(tidyverse)
library(readxl)
library(survey)

# IMPORT DATA -----

# first, read in nhanes food-level data

day1 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day1_clean.rds")

day1_sub <- day1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DR1IGRMS, DESCRIPTION)

day2 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day2_clean.rds")

day2_sub <- day2 %>% select(SEQN, DR2ILINE, DR2IFDCD, DR2IGRMS, DESCRIPTION)

rm(day1, day2)

# import 
map <- read_csv("in/Environmental impact (Brooke)/raw data/FCID_0118_LASTING.csv")

map1 <- map %>% select(foodcode, fcidcode, fcid_desc, wt)

# combine with food data
day1_map <- full_join(map1, day1_sub, by = c("foodcode" = "DR1IFDCD"))

day1_map_sub <- day1_map %>% filter(!(is.na(DR1IGRMS))) %>% arrange(SEQN, DR1ILINE)

day2_map <- full_join(map1, day2_sub, by = c("foodcode" = "DR2IFDCD"))

day2_map_sub <- day2_map %>% filter(!(is.na(DR2IGRMS))) %>% arrange(SEQN, DR2ILINE)

# # how many missing FCIDs? 3,197 rows
# day1_map_sub %>% filter(is.na(fcidcode)) %>% View()
# 
# # what are unique food items? 55 items, not bad
# day1_map_sub %>% filter(is.na(fcidcode)) %>% select(foodcode, DESCRIPTION) %>% distinct() %>% View()

# import datafield
df <- read_xlsx("in/Environmental impact (Brooke)/raw data/dataFIELDv1.0.xlsx",
                sheet = "FCID linkages",
                skip = 2)

df_sub <- df %>% 
  select(FCID_Code, `MJ / kg`, `CO2 eq / kg`) %>% 
  rename(GHG_impact_kg = `CO2 eq / kg`,
         CED_impact_kg = `MJ / kg`,
         fcidcode = FCID_Code) %>% 
  mutate(GHG_impact_g = GHG_impact_kg / 1000,
         CED_impact_g = CED_impact_kg / 1000)

# now merge
comb_day1 <- left_join(day1_map_sub, df_sub)

comb_day2 <- left_join(day2_map_sub, df_sub)

# import fcid-diet factor mapping
new_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup) %>% 
  rename(fcidcode = FCID_Code)

comb_day1_new <- 
  left_join(comb_day1, new_map) %>% 
  # rearrange columns
  select(SEQN, DR1ILINE, foodcode, DESCRIPTION, DR1IGRMS, fcidcode, 
         fcid_desc, Foodgroup, wt, GHG_impact_g, CED_impact_g) %>% 
  
  mutate(grams_fcid = DR1IGRMS * (wt/100),
         
         # calculate GHG and CED impact for each FCID item
         fcid_GHG_impact = grams_fcid * GHG_impact_g,
         fcid_CED_impact = grams_fcid * CED_impact_g)

comb_day2_new <- 
  left_join(comb_day2, new_map) %>% 
  # rearrange columns
  select(SEQN, DR2ILINE, foodcode, DESCRIPTION, DR2IGRMS, fcidcode, 
         fcid_desc, Foodgroup, wt, GHG_impact_g, CED_impact_g) %>% 
  
  mutate(grams_fcid = DR2IGRMS * (wt/100),
         
         # calculate GHG and CED impact for each FCID item
         fcid_GHG_impact = grams_fcid * GHG_impact_g,
         fcid_CED_impact = grams_fcid * CED_impact_g)

# export these datasets
write_csv(comb_day1_new, "in/Environmental impact (Brooke)/clean data/Enviromental_impact_by_fcidcode_day1_07272023.csv")
write_csv(comb_day2_new, "in/Environmental impact (Brooke)/clean data/Enviromental_impact_by_fcidcode_day2_07272023.csv")

# sum the impact per person, per dietary factor
day1_sum_impact <- comb_day1_new %>% 
  group_by(SEQN, Foodgroup) %>% 
  summarise(ghg_impact_day1 = sum(fcid_GHG_impact),
            ced_impact_day1 = sum(fcid_CED_impact)) %>% 
  filter(!(is.na(Foodgroup))) %>% 
  replace(is.na(.), 0)

day2_sum_impact <- comb_day2_new %>% 
  group_by(SEQN, Foodgroup) %>% 
  summarise(ghg_impact_day2 = sum(fcid_GHG_impact),
            ced_impact_day2 = sum(fcid_CED_impact)) %>% 
  filter(!(is.na(Foodgroup))) %>% 
  replace(is.na(.), 0)

# full join
sum_impact <- full_join(day1_sum_impact, day2_sum_impact)

sum_impact1 <- sum_impact %>% 
  rowwise() %>% 
  mutate(GHG_impact_avg = mean(c(ghg_impact_day1, ghg_impact_day2), na.rm = TRUE),
         CED_impact_avg = mean(c(ced_impact_day1, ced_impact_day2), na.rm = TRUE))

# export
write_csv(sum_impact1, "in/Environmental impact (Brooke)/clean data/Enviromental_impact_by_person_07272023.csv")

# transform to wide
sum_impact_wide <- sum_impact1 %>% pivot_wider(id_cols = SEQN,
                                               names_from = Foodgroup,
                                               values_from = c(GHG_impact_avg, CED_impact_avg)) %>% 
  replace(is.na(.), 0) # might need to move this earlier


# CALCULATE ENVIRONMENTAL IMPACT, BY FOOD, BY SUBGROUP -----

# import subgroup-seqn mapping
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

# join
sum_impact_wide1 <- left_join(sum_impact_wide, subgroup_dat, by = "SEQN")

# create separate ghg and ced datasets
ghg_dat <- sum_impact_wide1 %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis, starts_with("GHG"))

# fix column names
colnames(ghg_dat) <- gsub("GHG_impact_avg_","",colnames(ghg_dat))

ced_dat <- sum_impact_wide1 %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis, starts_with("CED"))

# fix column names
colnames(ced_dat) <- gsub("CED_impact_avg_","",colnames(ced_dat))

# Define survey design for ghg dataset 
my_svy_ghg <- svydesign(data=ghg_dat, 
                          id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                          strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                          weights=~wtnew, # New sample weight
                          nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_ghg_sub <- subset(my_svy_ghg, inAnalysis==1)

# Define survey design for ghg dataset 
my_svy_ced <- svydesign(data=ced_dat, 
                        id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                        strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                        weights=~wtnew, # New sample weight
                        nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_ced_sub <- subset(my_svy_ced, inAnalysis==1)

# CALCULATE GHG IMPACT

allfoods_ghg_bysub <- svyby(~gr_refined+
                                gr_whole+
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
                                coffee_tea+
                                oil+
                                sat_fat+
                                other+
                                water,
                              ~subgroup, 
                              my_svy_ghg_sub, 
                              svymean)

# Reformat unadjusted output to match model data
my_se_ghg <- allfoods_ghg_bysub %>% select(subgroup, starts_with("se."))

my_mean_ghg <- allfoods_ghg_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_ghg_long <- my_se_ghg %>% pivot_longer(cols = starts_with("se."),
                                                 names_to = "food",
                                                 names_prefix = "se.",
                                                 values_to = "GHG_impact_se")

my_mean_ghg_long <- my_mean_ghg %>% pivot_longer(cols = !subgroup,
                                                     names_to = "food",
                                                     values_to = "GHG_impact_mean")

# combine
allfoods_ghg_bysub_long <- left_join(my_mean_ghg_long, my_se_ghg_long, by = c("subgroup", "food"))


# CALCULATE CED IMPACT

allfoods_ced_bysub <- svyby(~gr_refined+
                              gr_whole+
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
                              coffee_tea+
                              oil+
                              sat_fat+
                              other+
                              water,
                            ~subgroup, 
                            my_svy_ced_sub, 
                            svymean)

# Reformat unadjusted output to match model data
my_se_ced <- allfoods_ced_bysub %>% select(subgroup, starts_with("se."))

my_mean_ced <- allfoods_ced_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_ced_long <- my_se_ced %>% pivot_longer(cols = starts_with("se."),
                                             names_to = "food",
                                             names_prefix = "se.",
                                             values_to = "CED_impact_se")

my_mean_ced_long <- my_mean_ced %>% pivot_longer(cols = !subgroup,
                                                 names_to = "food",
                                                 values_to = "CED_impact_mean")

# combine
allfoods_ced_bysub_long <- left_join(my_mean_ced_long, my_se_ced_long, by = c("subgroup", "food"))


# ALL IMPACTS
all_impacts <- left_join(allfoods_ghg_bysub_long, allfoods_ced_bysub_long) %>% arrange(food, subgroup)

# export
write_csv(all_impacts, "in/Environmental impact (Brooke)/clean data/Enviromental_impact_by_subgroup_07272023.csv")



