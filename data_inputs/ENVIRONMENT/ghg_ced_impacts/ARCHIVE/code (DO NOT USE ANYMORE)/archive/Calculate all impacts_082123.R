# Calculate environmental impact and cost at food level
# Author: Brooke Bell
# Date: 8-21-23

rm(list = ls())

library(tidyverse)
library(readxl)
library(survey)

# NHANES FOOD DATA -----

# first, read in nhanes food-level data

day1 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day1_clean.rds")

day1_sub <- day1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DR1IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec, gr_whole, gr_refined) %>% 
  rename(seqn = SEQN,
         line = DR1ILINE,
         foodcode = DR1IFDCD,
         grams = DR1IGRMS,
         description = DESCRIPTION)

day2 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day2_clean.rds")

day2_sub <- day2 %>% select(SEQN, DR2ILINE, DR2IFDCD, DR2IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec, gr_whole, gr_refined) %>% 
  rename(seqn = SEQN,
         line = DR2ILINE,
         foodcode = DR2IFDCD,
         grams = DR2IGRMS,
         description = DESCRIPTION)

rm(day1, day2)

# combine day 1 and day 2
both_days <- rbind(day1_sub, day2_sub) %>% arrange(seqn, dayrec, line)

# MAPPING FROM FNDDS FOODCODE TO FCID CODE -----

# import 
map <- read_csv("in/Environmental impact (Brooke)/raw data/FCID_0118_LASTING.csv")

map1 <- map %>% select(foodcode, fcidcode, fcid_desc, wt)

# combine with food data
both_days1 <- full_join(both_days, map1, by = "foodcode")

both_days2 <- both_days1 %>% 
  filter(!(is.na(grams))) %>% 
  arrange(seqn, dayrec, line) %>% 
  relocate(c(foodsource, nhanes_cycle, dayrec), .after = last_col())

# LOSS WASTE DATA -----

# import losswaste data
losswaste <- read_csv("in/Environmental impact (Brooke)/raw data/losswaste.csv")

# merge with bothdays
both_days3 <- left_join(both_days2, losswaste, by = "fcidcode")

# need to eventually import the proxy data for missing loss/waste data


# FCID TO DIET MAPPING -----

# import fcid-diet factor mapping
new_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup) %>% 
  rename(fcidcode = FCID_Code)

# test
# left_join(new_map, food_cats, by = c("fcidcode" = "FCID ingredient code")) %>% View()

# merge
both_days4 <- left_join(both_days3, new_map, by = "fcidcode")

# only select food groups we want

diet_factors <- c("added_sugar", "dairy", "gr_refined", "gr_whole", "oil", 
                  "pf_egg", "pf_ns", "pf_pm", "pf_poultry", "pf_redm", "pf_seafood", 
                  "veg_dg", "veg_oth", "veg_ro", "veg_sta", "leg_tot",
                  "fruit_exc_juice", "fruit_juice", "ssb", 
                  # "coffee_tea", #for now, remove coffee/tea
                  "sat_fat")

# filter to only include the diet factors that we want (or missing)
both_days5 <- both_days4 %>% filter(Foodgroup %in% diet_factors | is.na(Foodgroup))

# which ones have missing food group?
both_days5 %>% filter(is.na(Foodgroup)) %>% select(foodcode, description) %>% distinct() %>% View()

# export
# no_fcids <- both_days10 %>% filter(is.na(Foodgroup)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_fcids, "in/Environmental impact (Brooke)/missing data/Missing FCIDS.csv")

# import new mapping
fcids_new <- read_csv("in/Environmental impact (Brooke)/missing data/Missing FCIDS_mapped.csv") %>% select(-description)

both_days6 <- rows_patch(both_days5, fcids_new, unmatched = "ignore")

# filter to only include diet factors
both_days7 <- both_days6 %>% filter(Foodgroup %in% diet_factors)

# which ones have missing fcid?
both_days7 %>% filter(is.na(fcidcode)) %>% View()
both_days7 %>% filter(is.na(fcidcode)) %>% select(foodcode, description, fcidcode) %>% distinct() %>% View()

# only 7 unique food items, which  make up very small amount of total food eaten

# if missing FCID, remove from dataset
# both_days13 <- both_days12 %>% filter(!(is.na(fcidcode)))

# calculate consumed_amt_g, inedible_amt_g, wasted_amt_g, total_amt_g
both_days8 <- both_days7 %>% 
  mutate(consumed_amt_g = grams * (wt / 100),
                      inedible_amt_g = consumed_amt_g * ined_coef,
                      wasted_amt_g = consumed_amt_g * waste_coef,
                      total_amt_g = consumed_amt_g + inedible_amt_g + wasted_amt_g)

# which FCIDs have missing waste data?
both_days8 %>% filter(is.na(waste_coef)) %>% select(fcidcode, fcid_desc) %>% distinct() %>% View()

# export
# no_waste <- both_days14 %>% filter(is.na(waste_coef)) %>% select(fcidcode, fcid_desc) %>% distinct()
# write_csv(no_waste, "in/Environmental impact (Brooke)/missing data/Missing waste coefficients.csv")


# FAH FAFH RATIOS -----

# import fah/fafh ratios
fafh <- read_csv("in/FAH FAFH ratio (Brooke)/results/fafh_fah_ratio_clean_07-06-23.csv") %>% 
  select(Diet_var, ratio_FAFH_FAH)

# join with both_days

both_days9 <- left_join(both_days8, fafh, by = c("Foodgroup" = "Diet_var"))

rm(list=setdiff(ls(), "both_days9"))

# DATAFIELD (ENVIRO IMPACTS) -----

# import datafield
datafield <- read_xlsx("in/Environmental impact (Brooke)/raw data/dataFIELDv1.0.xlsx",
                sheet = "FCID linkages",
                skip = 2)

datafield_sub <- datafield %>% 
  select(FCID_Code, `MJ / kg`, `CO2 eq / kg`) %>% 
  rename(GHG_impact_kg = `CO2 eq / kg`,
         CED_impact_kg = `MJ / kg`,
         fcidcode = FCID_Code) %>% 
  mutate(GHG_impact_g = GHG_impact_kg / 1000,
         CED_impact_g = CED_impact_kg / 1000)

# now merge
both_days10 <- left_join(both_days9, datafield_sub, by = "fcidcode")

both_days11 <- both_days10 %>%
  mutate(nhanes1516 = ifelse(nhanes_cycle == "2015-2016", 1, 0))

# any missing environment data?
both_days11 %>% filter(is.na(GHG_impact_kg)) %>% select(foodcode, description, fcidcode, fcid_desc, Foodgroup) %>% distinct() %>% View()
# very few

# COST DATA -----

# import price data
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
both_days12 <- left_join(both_days11, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
  mutate(foodcode = as.character(foodcode))

# write_rds(both_days18, "in/Environmental impact (Brooke)/clean data/All_impacts_by_fcidcode_08212023.rds")

# which foodcodes have missing price?
both_days12 %>% filter(is.na(price_100gm)) %>% select(foodcode, description) %>% distinct() %>% View()

#export
# no_price <- both_days12 %>% filter(is.na(price_100gm)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_price, "in/Environmental impact (Brooke)/missing data/Missing price.csv") #add food groups

# Create FNDDS to dietary factor mapping
both_days19 <-
  both_days18 %>%
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


# how many fndds codes don't have food group?
both_days19 %>% filter(is.na(fndds_food_group)) %>% select(foodcode, description) %>% distinct() %>% View()
# mostly alcohol and mixed dishes
# come back and manually code these

no_foodgroup <- both_days19 %>% filter(is.na(fndds_food_group)) %>% select(foodcode, description) %>% distinct() %>% arrange(foodcode)
write_csv(no_foodgroup, "in/Environmental impact (Brooke)/missing data/Missing food group.csv") 

# calculate adjusted price per gram
# calculate food-level impacts
both_days17 <- 
  both_days16 %>% 
  mutate(price_per_gram_adjusted = ifelse(foodsource == "Other", price_per_gram * ratio_FAFH_FAH, price_per_gram),
         
         price_impact_per_fndds = total_amt_g * price_per_gram_adjusted,
         ghg_impact_per_fcid = (consumed_amt_g + wasted_amt_g) * GHG_impact_g,
         ced_impact_per_fcid = (consumed_amt_g + wasted_amt_g) * CED_impact_g)

# export example data
ex <- both_days17 %>% filter(pf_pm_fcid_yes == 1 & (pf_redm_fcid_yes == 1 | pf_poultry_fcid_yes ==1))

write_csv(ex, "in/Environmental impact (Brooke)/clean data/Example_081623.csv")




# export
#write_csv(both_days14, "in/Environmental impact (Brooke)/clean data/All_impacts_by_fcidcode_08042023.csv")
write_rds(both_days18, "in/Environmental impact (Brooke)/clean data/All_impacts_by_fcidcode_08042023.rds")



# sum the impact per person, per dietary factor, per day
sum_impact <- both_days14 %>% 
  group_by(seqn, Foodgroup, dayrec) %>% 
  summarise(ghg_impact_per_day = sum(ghg_impact_per_fcid),
            ced_impact_per_day = sum(ced_impact_per_fcid),
            price_impact_per_day = sum(price_impact_per_fndds)) %>% 
  filter(!(is.na(Foodgroup))) %>% 
  replace(is.na(.), 0)

sum_impact_avg <- 
  sum_impact %>% 
  group_by(seqn, Foodgroup) %>% 
  summarise(ghg_impact_avg = mean(ghg_impact_per_day, na.rm = TRUE),
            ced_impact_avg = mean(ced_impact_per_day, na.rm = TRUE),
            price_impact_avg = mean(price_impact_per_day, na.rm = TRUE)) %>% 
  arrange(seqn, Foodgroup)

# export
write_csv(sum_impact_avg, "in/Environmental impact (Brooke)/clean data/All_impacts_by_person_08042023.csv")

# transform to wide
sum_impact_wide <- sum_impact_avg %>% pivot_wider(id_cols = seqn,
                                               names_from = Foodgroup,
                                               values_from = c(ghg_impact_avg, ced_impact_avg, price_impact_avg)) %>% 
  replace(is.na(.), 0) 


# CALCULATE ENVIRONMENTAL/COST IMPACT, BY FOOD, BY SUBGROUP -----

# import subgroup-seqn mapping
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

# join
sum_impact_wide1 <- left_join(sum_impact_wide, subgroup_dat, by = c("seqn" = "SEQN"))

# Define survey design for ghg dataset 
my_svy <- svydesign(data=sum_impact_wide1, 
                        id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                        strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                        weights=~wtnew, # New sample weight
                        nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_sub <- subset(my_svy, inAnalysis==1)

# CALCULATE GHG IMPACT

allfoods_ghg_bysub <- svyby(~ghg_impact_avg_gr_refined+
                              ghg_impact_avg_gr_whole+
                              ghg_impact_avg_dairy+
                              ghg_impact_avg_fruit_exc_juice+ 
                              ghg_impact_avg_fruit_juice+
                              ghg_impact_avg_veg_dg+
                              ghg_impact_avg_veg_oth+
                              ghg_impact_avg_veg_ro+
                              ghg_impact_avg_veg_sta+
                              ghg_impact_avg_pf_ns+
                              ghg_impact_avg_pf_egg+
                              ghg_impact_avg_pf_poultry+
                              ghg_impact_avg_pf_redm+
                              ghg_impact_avg_pf_seafood+
                              ghg_impact_avg_leg_tot+
                              ghg_impact_avg_added_sugar+
                              ghg_impact_avg_oil+
                              ghg_impact_avg_sat_fat,
                            ~subgroup, 
                            my_svy_sub, 
                            svymean)

# CALCULATE CED IMPACT

allfoods_ced_bysub <- svyby(~ced_impact_avg_gr_refined+
                              ced_impact_avg_gr_whole+
                              ced_impact_avg_dairy+
                              ced_impact_avg_fruit_exc_juice+ 
                              ced_impact_avg_fruit_juice+
                              ced_impact_avg_veg_dg+
                              ced_impact_avg_veg_oth+
                              ced_impact_avg_veg_ro+
                              ced_impact_avg_veg_sta+
                              ced_impact_avg_pf_ns+
                              ced_impact_avg_pf_egg+
                              ced_impact_avg_pf_poultry+
                              ced_impact_avg_pf_redm+
                              ced_impact_avg_pf_seafood+
                              ced_impact_avg_leg_tot+
                              ced_impact_avg_added_sugar+
                              ced_impact_avg_oil+
                              ced_impact_avg_sat_fat,
                            ~subgroup, 
                            my_svy_sub, 
                            svymean)

# CALCULATE PRICE IMPACT

allfoods_price_bysub <- svyby(~price_impact_avg_gr_refined+
                                price_impact_avg_gr_whole+
                                price_impact_avg_dairy+
                                price_impact_avg_fruit_exc_juice+
                                price_impact_avg_fruit_juice+
                                price_impact_avg_veg_dg+
                                price_impact_avg_veg_oth+
                                price_impact_avg_veg_ro+
                                price_impact_avg_veg_sta+
                                price_impact_avg_pf_ns+
                                price_impact_avg_pf_egg+
                                price_impact_avg_pf_poultry+
                                price_impact_avg_pf_redm+
                                price_impact_avg_pf_seafood+
                                price_impact_avg_leg_tot+
                                price_impact_avg_added_sugar+
                                price_impact_avg_oil+
                                price_impact_avg_sat_fat,
                            ~subgroup,
                            my_svy_sub,
                            svymean)


# create cleaning function
# x <- all_impacts
# y = "ghg"

clean_func <- function(x, y){
  
  x1 <- x %>% select(subgroup, contains(y))
  
  my_se <- x1 %>% select(subgroup, starts_with("se."))
  my_mean <- x1 %>% select(subgroup, !starts_with("se."))
  
  # transform both datsets to long
  my_se_long <- my_se %>% pivot_longer(cols = starts_with("se."),
                                       names_to = "food",
                                       names_prefix = c("se."),
                                       values_to = paste0(y, "_impact_se"))
  
  my_mean_long <- my_mean %>% pivot_longer(cols = !subgroup,
                                                   names_to = "food",
                                                   values_to = paste0(y, "_impact_mean"))
  
  # join
  allfoods_bysub_long <- left_join(my_mean_long, my_se_long, by = c("subgroup", "food"))
  
  # need to fix names
  dat <- allfoods_bysub_long %>% mutate(food = gsub(paste0(y, "_impact_avg_"), "", food))
  
  print(dat)
  
}

ghg_dat <- clean_func(x = all_impacts, y = "ghg")
ced_dat <- clean_func(x = all_impacts, y = "ced")
price_dat <- clean_func(x = all_impacts, y = "price")

# ALL IMPACTS
final_dat <- left_join(ghg_dat, ced_dat, by = c("subgroup", "food")) %>% 
  left_join(price_dat, by = c("subgroup", "food")) %>% 
  arrange(food, subgroup)

# export
write_csv(final_dat, "in/Environmental impact (Brooke)/clean data/All_impacts_by_subgroup_08042023.csv")



