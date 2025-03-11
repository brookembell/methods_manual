# Try to figure out red and processed meat 
# Author: Brooke Bell
# Date: 8-4-23

rm(list = ls())

library(tidyverse)
library(readxl)
library(survey)

# IMPORT DATA -----

# first, read in nhanes food-level data

day1 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day1_clean.rds")

day1_sub <- day1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DR1IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec, pf_redm, pf_pm, pf_poultry, DR1I_PF_MPS_TOTAL) %>% 
  rename(seqn = SEQN,
         line = DR1ILINE,
         foodcode = DR1IFDCD,
         grams = DR1IGRMS,
         description = DESCRIPTION,
         pf_meat = DR1I_PF_MPS_TOTAL)

day2 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day2_clean.rds")

day2_sub <- day2 %>% select(SEQN, DR2ILINE, DR2IFDCD, DR2IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec, pf_redm, pf_pm, pf_poultry, DR2I_PF_MPS_TOTAL) %>% 
  rename(seqn = SEQN,
         line = DR2ILINE,
         foodcode = DR2IFDCD,
         grams = DR2IGRMS,
         description = DESCRIPTION,
         pf_meat = DR2I_PF_MPS_TOTAL)

rm(day1, day2)


# combine day 1 and day 2
both_days <- rbind(day1_sub, day2_sub) %>% arrange(seqn, dayrec, line)




# look at rows where there is any meat
both_days %>% filter(pf_pm > 0) %>% View()

# import 
map <- read_csv("in/ENVIRONMENT PILLAR/Environmental impact/raw data/FCID_0118_LASTING.csv")

map1 <- map %>% select(foodcode, fcidcode, fcid_desc, wt)

# combine with food data
both_days1 <- full_join(both_days, map1, by = "foodcode")

both_days1 %>% filter(pf_pm > 0) %>% View()

both_days2 <- both_days1 %>% 
  filter(!(is.na(grams))) %>% 
  arrange(seqn, dayrec, line) %>% 
  relocate(c(foodsource, nhanes_cycle, dayrec), .after = last_col())

both_days3 <-
  both_days2 %>% 
  mutate(fndds_food_group = case_when(substr(foodcode, 1, 1) == "1" ~ "dairy",
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
                                      substr(foodcode, 1, 2) == "75" ~ "veg_oth")) 


# look at processed meat
both_days3 %>% filter(fndds_food_group == "pf_pm") %>% View()

# look at FCIDs that represent meat

# From Conrad 2022, Supp Table 2:
# Beef = 31
# Pork = 34
# Other meat = 32, 35, 38, 39
# Poultry = 40, 50, 60

# import fcid food categories
food_cats <- read_csv("in/ENVIRONMENT PILLAR/FCID to diet/data/FCID_food_category.csv")

# only keep meat categories
meat_cats <- food_cats %>% filter(`Food category` %in% c("Beef", "Pork", "Other meat", "Poultry"))

# create ids vector
meat_ids <- meat_cats %>% select(`FCID ingredient code`) %>% unlist() %>% as.vector()

both_days3 %>% filter(fcidcode %in% meat_ids) %>% View()

# create fcid_meat_yes var
both_days4 <- both_days3 %>% mutate(fcid_meat_yes = ifelse((fcidcode %in% meat_ids) & pf_meat > 0, 1, 0)) 

# just deal with meat for now
meat <- both_days4 %>% filter(fcid_meat_yes == 1)

# create pct vars
meat1 <- meat %>% 
  rowwise() %>% 
  mutate(redm_pct = pf_redm / pf_meat,
         pm_pct = pf_pm / pf_meat,
         poultry_pct = pf_poultry / pf_meat)

# look at rows where pm_pct is between 0 and 1

meat1 %>% filter(pm_pct > 0 & pm_pct < 1) %>% View()

meat2 <- meat1 %>% mutate(commodity_wt_redm = wt * redm_pct,
                          commodity_wt_pm = wt * pm_pct,
                          commodity_wt_poultry = wt * poultry_pct,
                          
                          pf_redm_fcid_intake_grams = grams * commodity_wt_redm / 100,
                          pf_pm_fcid_intake_grams = grams * commodity_wt_pm / 100,
                          pf_poultry_fcid_intake_grams = grams * commodity_wt_poultry / 100)



