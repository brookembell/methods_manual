# Calculate environmental impact and cost at food level
# Author: Brooke Bell
# Date: 09-11-23

rm(list = ls())

options(scipen=999)

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

# check to make sure the formatting worked

both_days %>% filter(description == "Meat, NFS") %>% View() #looks good!

# MAPPING FROM FNDDS FOODCODE TO DIETARY FACTOR -----

# read in mapping

map_a <- read_csv("in/Environmental impact (Brooke)/raw data/Food_to_FNDDS_mapping_detailed_09-04-23.csv")

map_b <- read_csv("in/Environmental impact (Brooke)/raw data/Food_to_FNDDS_mapping_WHOLE_GRAINS_ONLY_09-04-23.csv")


# create all foodcodes vector
all_foodcodes <- both_days %>% select(foodcode) %>% distinct()

foo <- both_days1 %>% select(foodcode, description, Foodgroup) %>% distinct()

seafood <- foo %>% filter(Foodgroup == "pf_seafood") %>% distinct()

write_csv(seafood, "in/Dietary intake (Brooke)/Seafood FNDDS codes.csv")



# join
my_join <- full_join(mutate(all_foodcodes, i=1), 
          mutate(map_a, i=1)) %>% 
  select(-i) %>% 
  filter(str_detect(foodcode, paste0("^", foodcode_prefix))) %>% 
  select(-foodcode_prefix)

# now join with whole grain map

my_join1 <- rbind(my_join, map_b) %>% arrange(foodcode)

# there are 9 foodcodes that don;t have a mapping - which ones??

# temp_all_ids <- all_foodcodes %>% unlist() %>% as.vector()
# 
# temp_most_ids <- my_join1 %>% select(foodcode) %>% unlist() %>% as.vector()
# 
# temp_missing_ids <- temp_all_ids[!(temp_all_ids %in% temp_most_ids)]

both_days1 <- left_join(both_days, my_join1, by = "foodcode")


# how many fndds codes don't have food group?
both_days1 %>% 
  filter(is.na(Foodgroup)) %>% 
  select(foodcode, description) %>% 
  distinct() %>% 
  arrange(foodcode) %>% 
  View()

# mostly alcohol and mixed dishes
# come back and manually code these

no_foodgroup <- both_days1 %>% filter(is.na(Foodgroup)) %>% select(foodcode, description) %>% distinct() %>% arrange(foodcode)

# write_csv(no_foodgroup, "in/Environmental impact (Brooke)/missing data/Missing food group.csv") 

no_foodgroup_ids <- no_foodgroup %>% select(foodcode) %>% unlist() %>% as.vector()

# manually add these to csv file

map_b %>% filter(foodcode == "53215500")

map_b %>% filter(is.na(Foodgroup))

both_days1 %>% filter(foodcode == "53215500") %>% View()

both_days1 %>% filter(foodcode %in% no_foodgroup_ids) %>% View()

# import new mapping
map_a_v2 <- read_csv("in/Environmental impact (Brooke)/raw data/Food_to_FNDDS_mapping_detailed_09-04-23_v2.csv")

# join
my_join_new <- full_join(mutate(all_foodcodes, i=1), 
                     mutate(map_a_v2, i=1)) %>% 
  select(-i) %>% 
  filter(str_detect(foodcode, paste0("^", foodcode_prefix))) %>% 
  select(-foodcode_prefix)

# now join with whole grain map
my_join_new1 <- rbind(my_join_new, map_b) %>% arrange(foodcode)


both_days2 <- left_join(both_days, my_join_new1, by = "foodcode")


# how many fndds codes don't have food group?
both_days2 %>% 
  filter(is.na(Foodgroup)) %>% 
  select(foodcode, description) %>% 
  distinct() %>% 
  arrange(foodcode) %>% 
  View()

# okay manually fixed again

# import new wg mapping
map_b_v2 <- read_csv("in/Environmental impact (Brooke)/raw data/Food_to_FNDDS_mapping_WHOLE_GRAINS_ONLY_09-04-23_v2.csv")

# now join with whole grain map
my_join_new_ <- rbind(my_join_new, map_b_v2) %>% arrange(foodcode)


both_days3 <- left_join(both_days, my_join_new_, by = "foodcode")


# how many fndds codes don't have food group?
both_days3 %>% 
  filter(is.na(Foodgroup)) %>% 
  select(foodcode, description) %>% 
  distinct() %>% 
  arrange(foodcode) %>% 
  View()

# None!! woo good job :)

# check oil
both_days3 %>% filter(Foodgroup == "oil") %>% View() #looks good

# remove if missing grams value - just human breast milk
both_days3 %>% filter(is.na(grams)) %>% View()

both_days4 <- both_days3 %>% filter(!(is.na(grams)))

# clear out global environment
rm(list=setdiff(ls(), "both_days4"))

# MAPPING FROM FNDDS FOODCODE TO FCID CODE -----

# import 
map <- read_csv("in/Environmental impact (Brooke)/raw data/FCID_0118_LASTING.csv")

map1 <- map %>% select(foodcode, fcidcode, fcid_desc, wt)

# combine with food data
both_days5 <- full_join(both_days4, map1, by = "foodcode")

# remove if missing SEQN - foodcodes that no one ate
both_days5 %>% filter(is.na(grams)) %>% View()

both_days6 <- both_days5 %>% 
  filter(!(is.na(seqn))) %>% 
  arrange(seqn, dayrec, line) %>% 
  relocate(c(foodsource, nhanes_cycle, dayrec), .after = last_col())

# clear out global environment
# rm(list=setdiff(ls(), "both_days6"))

# LOSS WASTE DATA -----

# import losswaste data
losswaste <- read_csv("in/Environmental impact (Brooke)/raw data/losswaste.csv")

# need to import the proxy data for missing loss/waste data

losswaste_complete <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing waste coefficients (full)_090523.csv") %>% 
  select(-c(fcid_desc, Foodgroup, Proxy, Notes))

# losswaste_complete %>% select(fcidcode) %>% distinct() %>% nrow()

# merge with bothdays
both_days7 <- left_join(both_days6, losswaste_complete, by = "fcidcode")

# clear out global environment
# rm(list=setdiff(ls(), "both_days7"))

# FCID TO DIET MAPPING -----

# import fcid-diet factor mapping
new_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup) %>% 
  rename(fcidcode = FCID_Code,
         Foodgroup_FCID = Foodgroup)

# test
# left_join(new_map, food_cats, by = c("fcidcode" = "FCID ingredient code")) %>% View()

# merge
both_days8 <- left_join(both_days7, new_map, by = "fcidcode")

# only select food groups we want

diet_factors <- c("added_sugar", "dairy", "gr_refined", "gr_whole", "oil", 
                  "pf_egg", "pf_ns", "pf_pm", "pf_poultry", "pf_redm", "pf_seafood", 
                  "veg_dg", "veg_oth", "veg_ro", "veg_sta", "leg_tot",
                  "fruit_exc_juice", "fruit_juice", "ssb", 
                  # "coffee_tea", #for now, remove coffee/tea
                  "sat_fat")

# filter to only include the diet factors that we want (or missing)
both_days9 <- both_days8 %>% filter(Foodgroup_FCID %in% diet_factors | is.na(Foodgroup_FCID))


# which FNDDS foodcodes have missing FCID food group?
both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% View()

both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct() %>% View()

# export
no_fcids <- both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_fcids, "in/Environmental impact (Brooke)/missing data/Missing FCIDS.csv")

# import new mapping
fcids_new <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing FCIDS_mapped.csv") %>% 
  select(-description) %>% 
  rename(Foodgroup_FCID = Foodgroup)

both_days10 <- rows_patch(both_days9, fcids_new, unmatched = "ignore")

# filter to only include diet factors
both_days11 <- both_days10 %>% filter(Foodgroup_FCID %in% diet_factors)

# which ones have missing fcid?
both_days11 %>% filter(is.na(fcidcode)) %>% View()

both_days11 %>% filter(is.na(fcidcode)) %>% select(foodcode, description, fcidcode) %>% distinct() %>% View()

# for some of these, the FNDDS foodcode can represent the FCID (single items)
# I will manually add these waste coefficients for dasheen and corn

#dasheen
dash <- losswaste_complete %>% filter(fcidcode == "103139000") %>% 
  #change the fcidcode
  mutate(foodcode = 71962020,
         wt = 100)

corn <- losswaste_complete %>% filter(fcidcode == "1500127000") %>% 
  #change the fcidcode
  mutate(foodcode = 75215990, 
         wt = 100)

comb <- rbind(dash, corn) %>% select(-fcidcode)

# row patch with bothdays11
both_days12 <- rows_patch(both_days11, comb, by = "foodcode")

# check missing fcid
both_days12 %>% filter(is.na(fcidcode)) %>% View()

# check missing waste coef
both_days12 %>% filter(is.na(waste_coef)) %>% View()

# there's very few foodcodes left that don't have waste and inedible coefficients

# if missing FCID, remove from dataset
# both_days13 <- both_days12 %>% filter(!(is.na(fcidcode)))

# calculate consumed_amt_g, inedible_amt_g, wasted_amt_g, total_amt_g
both_days13 <- both_days12 %>% 
  mutate(consumed_amt_g = grams * (wt / 100),
                      inedible_amt_g = consumed_amt_g * ined_coef,
                      wasted_amt_g = consumed_amt_g * waste_coef,
                      total_amt_g = consumed_amt_g + inedible_amt_g + wasted_amt_g)

# how many rows have missing consumed_amt? only 10 rows total
both_days13 %>% filter(is.na(consumed_amt_g)) %>% View()

# export
# no_waste <- both_days14 %>% filter(is.na(waste_coef)) %>% select(fcidcode, fcid_desc) %>% distinct()
# write_csv(no_waste, "in/Environmental impact (Brooke)/missing data/Missing waste coefficients.csv")

# clear out global environment
# rm(list=setdiff(ls(), "both_days13"))

# FAH FAFH RATIOS -----

# import fah/fafh ratios
fafh <- read_csv("in/FAH FAFH ratio (Brooke)/results/fafh_fah_ratio_clean_07-06-23.csv") %>% 
  select(Diet_var, ratio_FAFH_FAH)

# join with both_days

both_days14 <- left_join(both_days13, fafh, by = c("Foodgroup" = "Diet_var"))

# any missing ratios?
both_days14 %>% filter(is.na(ratio_FAFH_FAH)) %>% View()

both_days14 %>% filter(is.na(ratio_FAFH_FAH)) %>% select(Foodgroup) %>% distinct()
# these are all water or babyfood

# okay, time to filter by diet factors
# this will remove FNDDS codes that represent water or babyfood

both_days15 <- both_days14 %>% 
  rename(Foodgroup_FNDDS = Foodgroup) %>% 
  filter(Foodgroup_FNDDS %in% diet_factors) 

# any missing ratios?
both_days15 %>% filter(is.na(ratio_FAFH_FAH)) %>% View() #none-good

# rm(list=setdiff(ls(), "both_days15"))

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
both_days16 <- left_join(both_days15, datafield_sub, by = "fcidcode")


# any missing ghg impact factors?
both_days16 %>% filter(is.na(GHG_impact_g)) %>% View()

# create dataset to export
missing_ghg <- 
  both_days16 %>% 
  filter(is.na(GHG_impact_g) & !(is.na(consumed_amt_g))) %>% 
  select(foodcode, description, fcidcode, fcid_desc) %>% 
  distinct()

# export 
write_csv(missing_ghg, "in/Environmental impact (Brooke)/missing data/Missing environmental impacts.csv")

# import proxies for missing enviro data
ghg_proxies <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing environmental impacts_mapped.csv")

ghg_proxies_sub <- ghg_proxies %>% 
  select(foodcode, description, proxy_fcidcode, proxy_desc) %>% 
  rename(fcidcode = proxy_fcidcode,
         fcid_desc = proxy_desc)

both_days16_ <- rows_update(both_days16, ghg_proxies_sub, by = c("foodcode", "description"))

# check corn
both_days16_ %>% filter(foodcode == 75215990) %>% View() # good

# fcid should be herb
both_days16_ %>% filter(foodcode == 72133200) %>% View() #good!

# insert enviro data for fcids that were originally missing
both_days16_1 <- both_days16_ %>% rows_patch(datafield_sub, by = "fcidcode", unmatched = "ignore") 

# check corn
both_days16_1 %>% filter(foodcode == 75215990) %>% View()

# confirm there are no more missing FCIDs
both_days16_1 %>% filter(is.na(fcidcode)) %>% View() # good

# confirm there are no more missing GHG
both_days16_1 %>% filter(is.na(GHG_impact_g)) %>% View() # good

# create new var
both_days17 <- both_days16_1 %>%
  mutate(nhanes1516 = ifelse(nhanes_cycle == "2015-2016", 1, 0))

# clear out global environment
rm(list=setdiff(ls(), "both_days17"))

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
both_days18 <- left_join(both_days17, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
  mutate(foodcode = as.character(foodcode))

# how many are missing price data?
both_days18 %>% filter(is.na(price_per_gram))

both_days18 %>% filter(is.na(price_100gm)) %>% select(foodcode, description, Foodgroup_FNDDS) %>% distinct() %>% View()

# need to impute average value into missing

imputed_price <-
  both_days18 %>% 
  select(seqn, line, foodcode, Foodgroup_FNDDS, foodsource, price_per_gram) %>% 
  distinct() %>% 
  group_by(Foodgroup_FNDDS, foodsource) %>% 
  summarise(price_g_group_mean = mean(price_per_gram, na.rm = TRUE),
            price_g_group_median = median(price_per_gram, na.rm = TRUE),
            price_g_group_sd = sd(price_per_gram, na.rm = TRUE))

#export
# no_price <- both_days12 %>% filter(is.na(price_100gm)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_price, "in/Environmental impact (Brooke)/missing data/Missing price.csv") #add food groups


both_days19 <- left_join(both_days18, imputed_price, by = c("Foodgroup_FNDDS", "foodsource"))

both_days20 <- both_days19 %>% 
  mutate(price_per_gram = ifelse(is.na(price_per_gram), price_g_group_median, price_per_gram))

# check if any missing price per gram (shouldn't be)
both_days20 %>% filter(is.na(price_per_gram)) #none-good

# PRICE IMPACTS, PER FNDDS

my_price_table <- both_days20 %>% 
  select(seqn, line, foodcode, grams, description, Foodgroup_FNDDS, foodsource, dayrec, ratio_FAFH_FAH, price_per_gram) %>% 
  distinct()

my_price_table1 <- my_price_table %>% mutate(price_per_gram_adjusted = ifelse(foodsource == "Other", 
                                                           price_per_gram * ratio_FAFH_FAH, 
                                                           price_per_gram),
                          price_impact_per_fndds = grams * price_per_gram_adjusted)

price_impact <- my_price_table1 %>% 
  group_by(seqn, Foodgroup_FNDDS, dayrec) %>% 
  summarise(price_per_day = sum(price_impact_per_fndds)) %>% 
  filter(!(is.na(Foodgroup_FNDDS))) %>% 
  replace(is.na(.), 0)

price_impact_avg <- price_impact %>% 
  group_by(seqn, Foodgroup_FNDDS) %>% 
  summarise(price_impact_avg = mean(price_per_day, na.rm = TRUE)) %>% 
  arrange(seqn, Foodgroup_FNDDS)

# transform to wide
price_impact_wide <- price_impact_avg %>% pivot_wider(id_cols = seqn,
                                                  names_from = Foodgroup_FNDDS,
                                                  values_from = price_impact_avg,
                                                  names_prefix = "cost_") %>% 
  replace(is.na(.), 0) 
  
# ENVIRONMENTAL IMPACTS, PER FCID

both_days21 <- 
  both_days20 %>% 
  mutate(
    ghg_impact_per_fcid = (consumed_amt_g + wasted_amt_g) * GHG_impact_g,
    ced_impact_per_fcid = (consumed_amt_g + wasted_amt_g) * CED_impact_g)

# export
#write_csv(both_days21, "in/Environmental impact (Brooke)/clean data/All_impacts_by_fcidcode_08042023.csv")

# sum the impact per person, per dietary factor, per day
sum_impact <- both_days21 %>% 
  group_by(seqn, Foodgroup_FCID, dayrec) %>% 
  summarise(ghg_impact_per_day = sum(ghg_impact_per_fcid),
            ced_impact_per_day = sum(ced_impact_per_fcid)) %>% 
  filter(!(is.na(Foodgroup_FCID))) %>% 
  replace(is.na(.), 0)

sum_impact_avg <- 
  sum_impact %>% 
  group_by(seqn, Foodgroup_FCID) %>% 
  summarise(ghg_impact_avg = mean(ghg_impact_per_day, na.rm = TRUE),
            ced_impact_avg = mean(ced_impact_per_day, na.rm = TRUE)) %>% 
  arrange(seqn, Foodgroup_FCID)

# export
# write_csv(sum_impact_avg, "in/Environmental impact (Brooke)/clean data/All_impacts_by_person_08042023.csv")

# transform to wide
sum_impact_wide <- sum_impact_avg %>% pivot_wider(id_cols = seqn,
                                               names_from = Foodgroup_FCID,
                                               values_from = c(ghg_impact_avg, ced_impact_avg)) %>% 
  replace(is.na(.), 0) 


# CALCULATE ENVIRONMENTAL IMPACT, BY FOOD, BY SUBGROUP -----

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

allfoods_ghg_bysub <- svyby(reformulate(names(sum_impact_wide1) %>% str_subset("ghg")),
                            ~subgroup,
                            my_svy_sub,
                            svymean)

# CALCULATE CED IMPACT

allfoods_ced_bysub <- svyby(reformulate(names(sum_impact_wide1) %>% str_subset("ced")),
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

ghg_dat <- clean_func(x = allfoods_ghg_bysub, y = "ghg")
ced_dat <- clean_func(x = allfoods_ced_bysub, y = "ced")

# ALL ENVIRO IMPACTS
enviro_dat <- left_join(ghg_dat, ced_dat, by = c("subgroup", "food")) %>% 
  arrange(food, subgroup)

# export
# write_csv(final_dat, "in/Environmental impact (Brooke)/clean data/All_impacts_by_subgroup_08042023.csv")

# CALCULATE COST IMPACT, BY FOOD, BY SUBGROUP -----

full_join(price_impact_wide, subgroup_dat, by = c("seqn" = "SEQN")) %>% View()

full_join(price_impact_wide, subgroup_dat, by = c("seqn" = "SEQN")) %>% 
  filter(is.na(cost_dairy) & inAnalysis == "TRUE") %>%  # only 1 person
  View()

# full join
price_impact_wide1 <- full_join(price_impact_wide, subgroup_dat, by = c("seqn" = "SEQN"))

# Define survey design for ghg dataset 
my_cost_svy <- svydesign(data=price_impact_wide1, 
                    id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                    strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                    weights=~wtnew, # New sample weight
                    nest=TRUE)

# Create a survey design object for the subset of interest 
my_cost_svy_sub <- subset(my_cost_svy, inAnalysis==1)


# CALCULATE COST

allfoods_cost_bysub <- svyby(reformulate(names(price_impact_wide1) %>% str_subset("cost")),
                            ~subgroup,
                            my_cost_svy_sub,
                            svymean)

x1 <- allfoods_cost_bysub %>% select(subgroup, contains("cost"))

my_se <- x1 %>% select(subgroup, starts_with("se."))
my_mean <- x1 %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_long <- my_se %>% pivot_longer(cols = starts_with("se."),
                                     names_to = "food",
                                     names_prefix = c("se."),
                                     values_to = paste0("cost_se"))

my_mean_long <- my_mean %>% pivot_longer(cols = !subgroup,
                                         names_to = "food",
                                         values_to = paste0("cost_mean"))

# join
allfoods_bysub_long <- left_join(my_mean_long, my_se_long, by = c("subgroup", "food"))

# need to fix names
cost_dat <- allfoods_bysub_long %>% mutate(food = gsub("cost_", "", food))

final_dat <- full_join(cost_dat, enviro_dat)

View(final_dat)

# missing enviro impacts for processed meat and SSB...
# need to figure out later...

# FINAL STEP
# TURN THESE INTO IMPACT FACTORS (IMPACT PER 1 GRAM)

# import diet intake (adjusted)
intake_bysub <- read_csv("in/Dietary intake (Brooke)/output data/NHANES_1518_summary_allfoods_adj_bysub_08-09-2023.csv")

# fix diet factor name
intake_bysub1 <- intake_bysub %>% 
  mutate(food = gsub("_adj", "", food)) %>% 
  select(-c(food_label, food_desc)) %>% 
  rename(intake_mean = mean,
         intake_se = SE)

# join

final_dat1 <- left_join(final_dat, intake_bysub1, by = c("subgroup", "food"))

# CREATE IMPACT FACTORS

final_dat2 <- final_dat1 %>% 
  rowwise() %>% 
  mutate(ghg_impact_per_fpe = ghg_impact_mean / intake_mean,
                      ced_impact_per_fpe = ced_impact_mean / intake_mean,
                      cost_impact_per_fpe = cost_mean / intake_mean) %>% 
  ungroup()

# VISUALIZATION; HISTOGRAMS OF IMPACT FACTORS

# add dem variables to dataset
dem <- nhanes %>% 
  select(subgroup, race, Race_label, age, Age_label, sex, Sex_label) %>% 
  filter(!(is.na(subgroup))) %>% 
  distinct() %>% 
  arrange(subgroup)

final_dat3 <- left_join(final_dat2, dem, by = "subgroup")


final_dat3 %>% 
  filter(food == "added_sugar") %>% 
  ggplot(mapping = aes(x=Race_label, y = ghg_impact_per_gram)) +
  geom_boxplot()

# export
write_csv(final_dat3, "in/Environmental impact (Brooke)/clean data/Impact_factors_by_subgroup_09112023.csv")

# THEN MATCH MEGA DATA FILE (Edit Fred code)
