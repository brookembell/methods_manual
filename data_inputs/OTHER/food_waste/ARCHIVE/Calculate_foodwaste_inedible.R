# Calculate group-level food waste & inedible proportions
# Author: Brooke Bell
# Date: 7-6-23

rm(list=ls())

library(tidyverse)
library(readxl)
library(haven)
library(psych)
library(survey)

# the first step is to disaggregate NHANES foods into their ingredients using the 
# FCID linkage file provided here, and then you can perform this step to estimate loss and waste. 

# then, multiply the NHANES consumption amount by the variable “waste_coef” to get the amount wasted


# This is mostly a translation of Lu's SAS code 'foodwaste_estimation.sas'

# Merge FCID_0118_LASTING.dta and losswaste.dta

fcid <- read_stata("in/Food waste (Brooke)/FCID_0118_LASTING.dta")

losswaste <- read_stata("in/Food waste (Brooke)/losswaste.dta")

comb <- left_join(fcid, losswaste, by = "fcidcode")

comb1 <- comb %>% select(foodcode, fcidcode, fcid_desc, wt,
                         waste_coef, ined_coef, retloss_coef)


# Read in NHANES food data

foods_day1 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day1_clean.rds")
foods_day2 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day2_clean.rds")

# create template dataset to join with

ids <- foods_day1 %>% select(SEQN) %>% distinct()

ids_day1 <- ids %>% mutate(day=1)
ids_day2 <- ids %>% mutate(day=2)

ids_tot <- full_join(ids_day1, ids_day2)

foods_tot <-
  ids_tot %>% 
  left_join(foods_day1) %>% 
  left_join(foods_day2) %>% 
  arrange(SEQN, day)

# combine more

foods_mega <- 
  full_join(foods_tot, comb1, by = c("DR1IFDCD" = "foodcode")) %>% 
  relocate(c(fcidcode, fcid_desc, wt, waste_coef, ined_coef, retloss_coef), 
           .after = "DESCRIPTION")

# Next steps:
# multiply fcid_gram = DR1IGRMS*wt/100 to get grams per fcid code
# then multiply waste_amt = fcid_gram * waste_coef

foods_mega1 <- foods_mega %>% mutate(fcid_gram = DR1IGRMS * wt / 100,
                      waste_amt = fcid_gram * waste_coef,
                      ined_amt = fcid_gram * ined_coef,
                      ed_amt = waste_amt + fcid_gram,
                      pur_amt = ed_amt + ined_amt) %>% 
  relocate(c(fcid_gram, waste_amt, ined_amt, ed_amt, pur_amt), 
           .after = "wt")

# remove datasets i'm not using anymore
rm(foods_day1, foods_day2, ids, ids_day1, ids_day2, ids_tot, foods_tot,
   comb)

# group by dietary factor

# need to merge with fcid-dietary factor spreadsheet
fcid_diet <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup)

# join with foods_mega1

foods_mega2 <- left_join(foods_mega1, fcid_diet, by = c("fcidcode" = "FCID_Code")) %>% 
  relocate(Foodgroup, .after = "fcidcode")

rm(foods_mega, foods_mega1)

#which ones have missing foodgroup?
foods_mega2 %>% filter(is.na(Foodgroup)) %>% 
  select(SEQN, DR1IFDCD, DR1IGRMS, DESCRIPTION, 
         fcidcode, fcid_desc, wt) %>%
  View()

foods_mega2 %>% filter(is.na(Foodgroup)) %>% 
  select(DR1IFDCD, DESCRIPTION, 
         fcidcode, fcid_desc) %>%
  distinct() %>% 
  View()
# mostly inconsequential food items

# first, calculate average waste amt, by person, by food group
amt_summary <- foods_mega2 %>% 
  group_by(SEQN, Foodgroup) %>% 
  summarise(avg_waste_amt = mean(waste_amt, na.rm=TRUE),
            avg_ined_amt = mean(ined_amt, na.rm=TRUE),
            avg_ed_amt = mean(ed_amt, na.rm=TRUE),
            avg_pur_amt = mean(pur_amt, na.rm=TRUE))

# remove foodgroups with missing
amt_summary1 <- amt_summary %>% filter(!(is.na(Foodgroup)))

# get rid of NaN
amt_summary1[amt_summary1 == "NaN"] <- NA

# transform to wide
amt_summary_wide <-
  pivot_wider(amt_summary1,
            names_from = Foodgroup,
            values_from = c(avg_waste_amt, avg_ined_amt, avg_ed_amt, avg_pur_amt)) %>% 
  filter(!(is.na(SEQN)))


waste_dat <- amt_summary_wide %>% select(SEQN, starts_with("avg_waste"))

# calculate mean by subgroup

# need dem data
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

nhanes_sub <- nhanes %>% 
  select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis, reliable_yes)

waste_dat1 <- full_join(waste_dat, nhanes_sub, by = "SEQN") %>% ungroup()

# Define survey design for overall dataset 
waste_svy <- svydesign(data=waste_dat1, 
                        id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                        strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                        weights=~wtnew, # New sample weight
                        nest=TRUE)

# Create a survey design object for the subset of interest 
# Subsetting the original survey design object ensures we keep the 
# design information about the number of clusters and strata
waste_svy_sub <- subset(waste_svy, inAnalysis==TRUE)

# test out
svymean(~avg_waste_amt_added_sugar, waste_svy_sub, na.rm = TRUE)

svyby(~avg_waste_amt_added_sugar, ~subgroup, waste_svy_sub, svymean, na.rm=TRUE, vartype = c("se", "ci"))




