# Calculate environmental impact and cost at food level
# Author: Brooke Bell
# Date: 10-06-23

rm(list = ls())

options(scipen=999)

library(tidyverse)
library(readxl)
library(survey)

# NHANES FOOD DATA -----

# first, read in nhanes food-level data

day1 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day1_clean.rds")

day1_sub <- day1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DR1IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec) %>% 
  rename(seqn = SEQN,
         line = DR1ILINE,
         foodcode = DR1IFDCD,
         grams = DR1IGRMS,
         description = DESCRIPTION)

day2 <- read_rds("in/Dietary intake (Brooke)/clean data/foods_day2_clean.rds")

day2_sub <- day2 %>% select(SEQN, DR2ILINE, DR2IFDCD, DR2IGRMS, DESCRIPTION, foodsource, nhanes_cycle, dayrec) %>% 
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

# Quickly get distinct seafood FNDDS codes
# foo <- both_days %>% select(foodcode, description, Foodgroup) %>% distinct()
# 
# seafood <- foo %>% filter(Foodgroup == "pf_seafood") %>% distinct()
# 
# write_csv(seafood, "in/Dietary intake (Brooke)/Seafood FNDDS codes.csv")

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
# both_days1 %>% 
#   filter(is.na(Foodgroup)) %>% 
#   select(foodcode, description) %>% 
#   distinct() %>% 
#   arrange(foodcode) %>% 
#   View()

# mostly alcohol and mixed dishes
# come back and manually code these

# no_foodgroup <- both_days1 %>% filter(is.na(Foodgroup)) %>% select(foodcode, description) %>% distinct() %>% arrange(foodcode)

# write_csv(no_foodgroup, "in/Environmental impact (Brooke)/missing data/Missing food group.csv") 

# no_foodgroup_ids <- no_foodgroup %>% select(foodcode) %>% unlist() %>% as.vector()

# manually add these to csv file

# map_b %>% filter(foodcode == "53215500")
# 
# map_b %>% filter(is.na(Foodgroup))
# 
# both_days1 %>% filter(foodcode == "53215500") %>% View()
# 
# both_days1 %>% filter(foodcode %in% no_foodgroup_ids) %>% View()

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
  arrange(foodcode)

# None!! woo good job :)

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
both_days5 %>% filter(is.na(grams)) 

both_days6 <- both_days5 %>% 
  filter(!(is.na(seqn))) %>% 
  arrange(seqn, dayrec, line) %>% 
  relocate(c(foodsource, nhanes_cycle, dayrec), .after = last_col())

# LOSS WASTE DATA -----

# import losswaste data
losswaste <- read_csv("in/Environmental impact (Brooke)/raw data/losswaste.csv")

# need to import the proxy data for missing loss/waste data

losswaste_complete <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing waste coefficients (full)_090523.csv") %>% 
  select(-c(fcid_desc, Foodgroup, Proxy, Notes))

# merge with bothdays
both_days7 <- left_join(both_days6, losswaste_complete, by = "fcidcode")

# FCID TO DIET MAPPING -----

# import fcid-diet factor mapping
new_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup) %>% 
  rename(fcidcode = FCID_Code,
         Foodgroup_FCID = Foodgroup)

# merge
both_days8 <- left_join(both_days7, new_map, by = "fcidcode")

# only select food groups we want
diet_factors <- c("added_sugar", "dairy", "gr_refined", "gr_whole", "oil", 
                  "pf_egg", "pf_ns", "pf_pm", "pf_poultry", "pf_redm", "pf_seafood", 
                  "veg_dg", "veg_oth", "veg_ro", "veg_sta", "leg_tot",
                  "fruit_exc_juice", "fruit_juice", "ssb", "sat_fat")

# filter to only include the diet factors that we want (or missing)
# undo for now
# both_days9 <- both_days8 %>% filter(Foodgroup_FCID %in% diet_factors | is.na(Foodgroup_FCID))

# which FNDDS foodcodes have missing FCID food group?
# both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% View()
# 
# both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct() %>% View()
# 
# # export
# no_fcids <- both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_fcids, "in/Environmental impact (Brooke)/missing data/Missing FCIDS.csv")

# import new mapping
fcids_new <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing FCIDS_mapped.csv") %>% 
  select(-description) %>% 
  rename(Foodgroup_FCID = Foodgroup)

both_days11 <- rows_patch(both_days8, fcids_new, unmatched = "ignore")

# filter to only include diet factors

# undo
# both_days11 <- both_days10 %>% filter(Foodgroup_FCID %in% diet_factors)

# which ones have missing fcid?
# both_days11 %>% filter(is.na(fcidcode)) %>% View()
# 
# both_days11 %>% filter(is.na(fcidcode)) %>% select(foodcode, description, fcidcode) %>% distinct() %>% View()

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

# calculate consumed_amt_g, inedible_amt_g, wasted_amt_g, total_amt_g
both_days13 <- both_days12 %>% 
  mutate(consumed_amt_FCID = grams * (wt / 100),
         inedible_amt_FCID = consumed_amt_FCID * ined_coef,
         wasted_amt_FCID = consumed_amt_FCID * waste_coef)
         #purchased_amt_FCID_Cost = consumed_amt_FCID + inedible_amt_FCID + wasted_amt_FCID,
         #purchased_amt_FCID_Env = consumed_amt_FCID + wasted_amt_FCID)

# calculate fndds-level inedible amt and wasted amt

both_days14 <-
  both_days13 %>% 
  group_by(seqn, dayrec, line, foodcode) %>% 
  mutate(consumed_amt_FNDDS = grams,
         inedible_amt_FNDDS = sum(inedible_amt_FCID, na.rm = TRUE),
         wasted_amt_FNDDS = sum(wasted_amt_FCID, na.rm = TRUE))
  # rowwise() %>% 
  # mutate(purchased_amt_FNDDS = sum(consumed_amt_FNDDS, inedible_amt_FNDDS, wasted_amt_FNDDS)) %>% 
  # ungroup()

# now check how many missing inedible_amt
both_days14 %>% filter(is.na(inedible_amt_FCID)) %>% View()

# how many rows have missing consumed_amt? only 10 rows total
# both_days14 %>% filter(is.na(purchased_amt_FNDDS)) %>% View()

# export
# no_waste <- both_days14 %>% filter(is.na(waste_coef)) %>% select(fcidcode, fcid_desc) %>% distinct()
# write_csv(no_waste, "in/Environmental impact (Brooke)/missing data/Missing waste coefficients.csv")

# FAH FAFH RATIOS -----

# import fah/fafh ratios
fafh <- read_csv("in/FAH FAFH ratio (Brooke)/results/fafh_fah_ratio_clean_07-06-23.csv") %>% 
  select(Diet_var, ratio_FAFH_FAH)

# join with both_days
both_days15 <- left_join(both_days14, fafh, by = c("Foodgroup" = "Diet_var"))

# any missing ratios?
both_days15 %>% filter(is.na(ratio_FAFH_FAH)) %>% View()

both_days15 %>% filter(is.na(ratio_FAFH_FAH)) %>% select(Foodgroup) %>% distinct()
# these are all water or babyfood

# okay, time to filter by diet factors
# this will remove FNDDS codes that represent water or babyfood

both_days16 <- both_days15 %>% 
  rename(Foodgroup_FNDDS = Foodgroup) %>% 
  #filter(Foodgroup_FNDDS %in% diet_factors) %>% 
  
  # just remove babyfood for now
  filter(Foodgroup_FNDDS != "babyfood") %>% 
  mutate(fcidcode = as.character(fcidcode))

# any missing ratios?
both_days16 %>% filter(is.na(ratio_FAFH_FAH)) %>% View()

# for now, assign ratio to 1 for water, but need to come back and add in real ratio later
both_days17 <- both_days16 %>% 
  mutate(ratio_FAFH_FAH = ifelse(Foodgroup_FNDDS == "water", 1, ratio_FAFH_FAH))

# any missing ratios?
both_days17 %>% filter(is.na(ratio_FAFH_FAH)) # none-good

# DATAFIELD (ENVIRO IMPACTS) -----

# import datafield
datafield <- read_xlsx("in/Environmental impact (Brooke)/raw data/dataFIELDv1.0.xlsx",
                sheet = "FCID linkages",
                skip = 2)

datafield_sub <- datafield %>% 
  select(FCID_Code, `MJ / kg`, `CO2 eq / kg`) %>% 
  rename(GHG_mn = `CO2 eq / kg`,
         CED_mn = `MJ / kg`,
         fcidcode = FCID_Code) %>% 
  mutate(fcidcode = as.character(fcidcode))

# now merge
both_days18 <- left_join(both_days17, datafield_sub, by = "fcidcode")

# any missing ghg impact factors?
both_days18 %>% filter(is.na(GHG_mn)) %>% View()

# create dataset to export
# missing_ghg <- 
#   both_days16 %>% 
#   filter(is.na(GHG_mn) & !(is.na(consumed_amt_g))) %>% 
#   select(foodcode, description, fcidcode, fcid_desc) %>% 
#   distinct()

# export 
# write_csv(missing_ghg, "in/Environmental impact (Brooke)/missing data/Missing environmental impacts.csv")

# import proxies for missing enviro data
ghg_proxies <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing environmental impacts_mapped.csv")

ghg_proxies_sub <- ghg_proxies %>% 
  select(foodcode, description, proxy_fcidcode, proxy_desc) %>% 
  rename(fcidcode = proxy_fcidcode,
         fcid_desc = proxy_desc) %>% 
  mutate(fcidcode = as.character(fcidcode))

both_days19 <- rows_update(both_days18, ghg_proxies_sub, by = c("foodcode", "description"))

# # check corn
# both_days16_ %>% filter(foodcode == 75215990) %>% View() # good
# 
# # fcid should be herb
# both_days16_ %>% filter(foodcode == 72133200) %>% View() #good!

# insert enviro data for fcids that were originally missing
both_days20 <- both_days19 %>% rows_patch(datafield_sub, by = "fcidcode", unmatched = "ignore") 

# # check corn
# both_days16_1 %>% filter(foodcode == 75215990) %>% View()
# 
# # confirm there are no more missing FCIDs
# both_days16_1 %>% filter(is.na(fcidcode)) %>% View() # good
# 
# # confirm there are no more missing GHG
both_days20 %>% filter(is.na(GHG_mn)) %>% View() 

both_days20 %>% filter(is.na(GHG_mn)) %>% select(description, Foodgroup_FCID) %>% distinct() %>% View()
# mostly babyfood and other foods - ignore for now

# create new var
both_days21 <- both_days20 %>%
  mutate(nhanes1516 = ifelse(nhanes_cycle == "2015-2016", 1, 0))

# clear out global environment
# rm(list=setdiff(ls(), "both_days21"))

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
both_days22 <- left_join(both_days21, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
  mutate(foodcode = as.character(foodcode))

# how many are missing price data?
# both_days18 %>% filter(is.na(price_per_gram))
both_days22 %>% filter(is.na(price_100gm)) %>% select(foodcode, description, Foodgroup_FNDDS) %>% distinct() %>% View()

# need to impute average value into missing

# !! come back and use the first 2 digits of fndds code as the grouping variable 
# to calculate median (or weighted mean) !!

imputed_price <-
  both_days22 %>% 
  select(seqn, line, foodcode, Foodgroup_FNDDS, foodsource, price_per_gram) %>% 
  distinct() %>% 
  group_by(Foodgroup_FNDDS, foodsource) %>% 
  summarise(price_g_group_mean = mean(price_per_gram, na.rm = TRUE),
            price_g_group_median = median(price_per_gram, na.rm = TRUE),
            price_g_group_sd = sd(price_per_gram, na.rm = TRUE))

#export
# no_price <- both_days12 %>% filter(is.na(price_100gm)) %>% select(foodcode, description) %>% distinct()
# write_csv(no_price, "in/Environmental impact (Brooke)/missing data/Missing price.csv") #add food groups

both_days23 <- left_join(both_days22, imputed_price, by = c("Foodgroup_FNDDS", "foodsource"))

# insert food_group median price if missing
both_days24 <- both_days23 %>% 
  mutate(price_per_gram = ifelse(is.na(price_per_gram), price_g_group_median, price_per_gram)) %>% 
  ungroup()

# check if any missing price per gram (shouldn't be)
both_days24 %>% filter(is.na(price_per_gram)) #none-good

# clear out global environment
rm(list=setdiff(ls(), "both_days24"))

# PRICE IMPACTS, PER FNDDS food code -----

my_price_table <- both_days24 %>% 
  select(seqn, dayrec, line, foodcode, description, Foodgroup_FNDDS, 
         consumed_amt_FNDDS, inedible_amt_FNDDS, wasted_amt_FNDDS, 
         #purchased_amt_FNDDS,
         foodsource, ratio_FAFH_FAH, price_per_gram) %>% 
  distinct() %>% 
  arrange(seqn, dayrec, line)

# look at missing
my_price_table %>% filter(is.na(inedible_amt_FNDDS) | is.na(wasted_amt_FNDDS)) %>% View()

# adjust price for FAFH
my_price_table1 <- my_price_table %>% mutate(price_per_gram_adjusted = ifelse(foodsource == "Other", 
                                                           price_per_gram * ratio_FAFH_FAH, 
                                                           price_per_gram),
                          price_impact_per_foodcode_Consumed = consumed_amt_FNDDS * price_per_gram_adjusted,
                          price_impact_per_foodcode_Inedible = inedible_amt_FNDDS * price_per_gram_adjusted,
                          price_impact_per_foodcode_Wasted = wasted_amt_FNDDS * price_per_gram_adjusted)

# TOTAL PRICE

price_impact_total <- my_price_table1 %>% 
  group_by(seqn, foodcode, dayrec) %>% 
  summarise(price_per_day_Consumed = sum(price_impact_per_foodcode_Consumed),
            price_per_day_Inedible = sum(price_impact_per_foodcode_Inedible),
            price_per_day_Wasted = sum(price_impact_per_foodcode_Wasted),

            consumed_per_day = sum(consumed_amt_FNDDS),
            inedible_per_day = sum(inedible_amt_FNDDS),
            wasted_per_day = sum(wasted_amt_FNDDS)) %>% 
  filter(!(is.na(foodcode))) %>% 
  replace(is.na(.), 0)

# average day 1 and day 2 prices for each fndds code
price_wide_total <- pivot_wider(price_impact_total, 
                          names_from = c(dayrec),
                          values_from = c(price_per_day_Consumed,
                                          price_per_day_Inedible,
                                          price_per_day_Wasted,
                                          
                                          consumed_per_day,
                                          inedible_per_day,
                                          wasted_per_day)) %>% 
  replace(is.na(.), 0) 

# summarize at food group level for each person
price_wide_total1 <- price_wide_total %>% 
  ungroup() %>% 
  rowwise() %>% 
  mutate(price_total_avg_Consumed = mean(c(price_per_day_Consumed_1, price_per_day_Consumed_2)),
         price_total_avg_Inedible = mean(c(price_per_day_Inedible_1, price_per_day_Inedible_2)),
         price_total_avg_Wasted = mean(c(price_per_day_Wasted_1, price_per_day_Wasted_2)),
         
         consumed_total_avg = mean(c(consumed_per_day_1, consumed_per_day_2)),
         inedible_total_avg = mean(c(inedible_per_day_1, inedible_per_day_2)),
         wasted_total_avg = mean(c(wasted_per_day_1, wasted_per_day_2))) %>% 
  
  select(seqn, foodcode, price_total_avg_Consumed, price_total_avg_Inedible, price_total_avg_Wasted,
         consumed_total_avg, inedible_total_avg, wasted_total_avg)

# STRATIFIED BY FAH VS FAFH

price_impact_split <- my_price_table1 %>% 
  # added foodsource 9/28/23
  group_by(seqn, foodcode, dayrec, foodsource) %>% 
  summarise(price_per_day_Consumed = sum(price_impact_per_foodcode_Consumed),
            price_per_day_Inedible = sum(price_impact_per_foodcode_Inedible),
            price_per_day_Wasted = sum(price_impact_per_foodcode_Wasted),
            
            consumed_per_day = sum(consumed_amt_FNDDS),
            inedible_per_day = sum(inedible_amt_FNDDS),
            wasted_per_day = sum(wasted_amt_FNDDS)) %>% 
  filter(!(is.na(foodcode))) %>% 
  replace(is.na(.), 0)

# average day 1 and day 2 prices for each fndds code
price_wide_split <- pivot_wider(price_impact_split, 
                          names_from = c(foodsource, dayrec),
                          values_from = c(price_per_day_Consumed,
                                          price_per_day_Inedible,
                                          price_per_day_Wasted,
                                          
                                          consumed_per_day,
                                          inedible_per_day,
                                          wasted_per_day)) %>% 
  replace(is.na(.), 0) 
  
# summarize at food group level for each person
price_wide_split1 <- price_wide_split %>% 
  ungroup() %>% 
  rowwise() %>% 
  mutate(#FAH (Grocery)
         price_fah_avg_Consumed = mean(c(price_per_day_Consumed_Grocery_1, price_per_day_Consumed_Grocery_2)),
         price_fah_avg_Inedible = mean(c(price_per_day_Inedible_Grocery_1, price_per_day_Inedible_Grocery_2)),
         price_fah_avg_Wasted = mean(c(price_per_day_Wasted_Grocery_1, price_per_day_Wasted_Grocery_2)),
         
         consumed_fah_avg = mean(c(consumed_per_day_Grocery_1, consumed_per_day_Grocery_2)),
         inedible_fah_avg = mean(c(inedible_per_day_Grocery_1, inedible_per_day_Grocery_2)),
         wasted_fah_avg = mean(c(wasted_per_day_Grocery_1, wasted_per_day_Grocery_2)),
         
         #FAFH (Other)
         price_fafh_avg_Consumed = mean(c(price_per_day_Consumed_Other_1, price_per_day_Consumed_Other_2)),
         price_fafh_avg_Inedible = mean(c(price_per_day_Inedible_Other_1, price_per_day_Inedible_Other_2)),
         price_fafh_avg_Wasted = mean(c(price_per_day_Wasted_Other_1, price_per_day_Wasted_Other_2)),
         
         consumed_fafh_avg = mean(c(consumed_per_day_Other_1, consumed_per_day_Other_2)),
         inedible_fafh_avg = mean(c(inedible_per_day_Other_1, inedible_per_day_Other_2)),
         wasted_fafh_avg = mean(c(wasted_per_day_Other_1, wasted_per_day_Other_2))) %>% 
  
  select(seqn, foodcode, 
         price_fah_avg_Consumed, price_fah_avg_Inedible, price_fah_avg_Wasted, consumed_fah_avg, inedible_fah_avg, wasted_fah_avg,
         price_fafh_avg_Consumed, price_fafh_avg_Inedible, price_fafh_avg_Wasted, consumed_fafh_avg, inedible_fafh_avg, wasted_fafh_avg)

# JOIN TOTAL AND SPLIT

price_wide_comb <- full_join(price_wide_total1, price_wide_split1, by = c("seqn", "foodcode"))

# first, read in mapping
map <- both_days24 %>%
  ungroup() %>% 
  select(foodcode, Foodgroup_FNDDS) %>% 
  distinct()

price_wide_comb1 <- left_join(price_wide_comb, map, by = "foodcode")

# add up prices by food group
price_wide_comb2 <- price_wide_comb1 %>% 
  group_by(seqn, Foodgroup_FNDDS) %>% 
  summarise(# Consumed
            price_total_sum_Consumed = sum(price_total_avg_Consumed),
            consumed_total_sum = sum(consumed_total_avg),
            
            price_fah_sum_Consumed = sum(price_fah_avg_Consumed),
            consumed_fah_sum = sum(consumed_fah_avg),
            
            price_fafh_sum_Consumed = sum(price_fafh_avg_Consumed),
            consumed_fafh_sum = sum(consumed_fafh_avg),
            
            # Inedible
            price_total_sum_Inedible = sum(price_total_avg_Inedible),
            inedible_total_sum = sum(inedible_total_avg),
            
            price_fah_sum_Inedible = sum(price_fah_avg_Inedible),
            inedible_fah_sum = sum(inedible_fah_avg),
            
            price_fafh_sum_Inedible = sum(price_fafh_avg_Inedible),
            inedible_fafh_sum = sum(inedible_fafh_avg),
            
            # Wasted
            price_total_sum_Wasted = sum(price_total_avg_Wasted),
            wasted_total_sum = sum(wasted_total_avg),
            
            price_fah_sum_Wasted = sum(price_fah_avg_Wasted),
            wasted_fah_sum = sum(wasted_fah_avg),
            
            price_fafh_sum_Wasted = sum(price_fafh_avg_Wasted),
            wasted_fafh_sum = sum(wasted_fafh_avg))
            
# transform to wide
price_wide_comb3 <- price_wide_comb2 %>% 
  pivot_wider(id_cols = seqn,
              names_from = Foodgroup_FNDDS,
              values_from = -c(seqn, Foodgroup_FNDDS)) %>% 
  replace(is.na(.), 0)

# manually add 1 participant who only drank water and nutritional drinks, none of which
# are any of the dietary factors we're examining

price_wide_comb4 <- full_join(price_wide_comb3, data.frame(seqn = 100844)) %>% 
  replace(is.na(.), 0)

# check
price_wide_comb4 %>% filter(seqn == "100844") #good
  
# ENVIRONMENTAL IMPACTS, PER FCID code -----

my_enviro_table <- 
  both_days24 %>% 
  mutate(
    GHG_impact_per_gram = GHG_mn / 1000,
    GHG_impact_per_FCID_Consumed = GHG_impact_per_gram * consumed_amt_FCID,
    GHG_impact_per_FCID_Inedible = GHG_impact_per_gram * inedible_amt_FCID,
    GHG_impact_per_FCID_Wasted = GHG_impact_per_gram * wasted_amt_FCID,
    
    CED_impact_per_gram = CED_mn / 1000,
    CED_impact_per_FCID_Consumed = CED_impact_per_gram * consumed_amt_FCID,
    CED_impact_per_FCID_Inedible = CED_impact_per_gram * inedible_amt_FCID,
    CED_impact_per_FCID_Wasted = CED_impact_per_gram * wasted_amt_FCID)


enviro_impact <- my_enviro_table %>% 
  group_by(seqn, fcidcode, dayrec) %>% 
  summarise(GHG_per_day_Consumed = sum(GHG_impact_per_FCID_Consumed),
            GHG_per_day_Inedible = sum(GHG_impact_per_FCID_Inedible),
            GHG_per_day_Wasted = sum(GHG_impact_per_FCID_Wasted),
            
            CED_per_day_Consumed = sum(CED_impact_per_FCID_Consumed),
            CED_per_day_Inedible = sum(CED_impact_per_FCID_Inedible),
            CED_per_day_Wasted = sum(CED_impact_per_FCID_Wasted),
            
            consumed_per_day = sum(consumed_amt_FCID),
            inedible_per_day = sum(inedible_amt_FCID),
            wasted_per_day = sum(wasted_amt_FCID)) %>% 
  filter(!(is.na(fcidcode))) %>% 
  replace(is.na(.), 0)

# average day 1 and day 2 impacts  for each fcid code
enviro_wide <- pivot_wider(enviro_impact, 
                          names_from = dayrec,
                          values_from = c(starts_with(c("GHG_per_day_", "CED_per_day_")), 
                                          "consumed_per_day", "inedible_per_day", "wasted_per_day")) %>% 
  replace(is.na(.), 0) 

enviro_wide1 <- enviro_wide %>% 
  ungroup() %>% 
  rowwise() %>% 
  mutate(ghg_impact_avg_Consumed = mean(c(GHG_per_day_Consumed_1, GHG_per_day_Consumed_2)),
         ghg_impact_avg_Inedible = mean(c(GHG_per_day_Inedible_1, GHG_per_day_Inedible_2)),
         ghg_impact_avg_Wasted = mean(c(GHG_per_day_Wasted_1, GHG_per_day_Wasted_2)),

         ced_impact_avg_Consumed = mean(c(CED_per_day_Consumed_1, CED_per_day_Consumed_2)),
         ced_impact_avg_Inedible = mean(c(CED_per_day_Inedible_1, CED_per_day_Inedible_2)),
         ced_impact_avg_Wasted = mean(c(CED_per_day_Wasted_1, CED_per_day_Wasted_2)),

         consumed_avg = mean(c(consumed_per_day_1, consumed_per_day_2)),
         inedible_avg = mean(c(inedible_per_day_1, inedible_per_day_2)),
         wasted_avg = mean(c(wasted_per_day_1, wasted_per_day_2))) %>% 
  select(seqn, fcidcode, starts_with(c("ghg_impact_avg_", "ced_impact_avg_")), consumed_avg, inedible_avg, wasted_avg)

# import fcid-diet factor mapping
new_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, Foodgroup) %>% 
  rename(fcidcode = FCID_Code,
         Foodgroup_FCID = Foodgroup) %>% 
  mutate(fcidcode = as.character(fcidcode))

enviro_wide2 <- enviro_wide1 %>% left_join(new_map, by = "fcidcode")

# add up enviro impacts, by food group
enviro_wide3 <- enviro_wide2 %>% 
  group_by(seqn, Foodgroup_FCID) %>% 
  summarise(ghg_impact_sum_Consumed = sum(ghg_impact_avg_Consumed),
            ghg_impact_sum_Inedible = sum(ghg_impact_avg_Inedible),
            ghg_impact_sum_Wasted = sum(ghg_impact_avg_Wasted),
            
            ced_impact_sum_Consumed = sum(ced_impact_avg_Consumed),
            ced_impact_sum_Inedible = sum(ced_impact_avg_Inedible),
            ced_impact_sum_Wasted = sum(ced_impact_avg_Wasted),
            
            consumed_sum = sum(consumed_avg),
            inedible_sum = sum(inedible_avg),
            wasted_sum = sum(wasted_avg))

# transform to wide
enviro_wide4 <- enviro_wide3 %>% 
  pivot_wider(id_cols = seqn,
              names_from = Foodgroup_FCID,
              values_from = !c(seqn, Foodgroup_FCID)) %>% 
  replace(is.na(.), 0)

# manually add 1 participant who only drank water and nutritional drinks, none of which
# are any of the dietary factors we're examining

enviro_wide5 <- full_join(enviro_wide4, data.frame(seqn = 100844)) %>% 
  replace(is.na(.), 0)

# check
enviro_wide5 %>% filter(seqn == "100844") #good

# CALCULATE COST IMPACT, BY FOOD, BY SUBGROUP -----

# import subgroup-seqn mapping
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

# full join
price_wide_comb5 <- full_join(price_wide_comb4, subgroup_dat, by = c("seqn" = "SEQN"))

# how many people have missing data but inanalysis=1?
# price_wide6 %>% filter(is.na(intake_sum_dairy) & inAnalysis == TRUE) %>% View()

# Define survey design for ghg dataset 
my_cost_svy <- svydesign(data=price_wide_comb5, 
                    id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                    strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                    weights=~wtnew, # New sample weight
                    nest=TRUE)

# Create a survey design object for the subset of interest 
my_cost_svy_sub <- subset(my_cost_svy, inAnalysis==1)

# CALCULATE COST
allfoods_cost_bysub <- svyby(reformulate(names(price_wide_comb5) %>% str_subset("price")),
                            ~subgroup,
                            my_cost_svy_sub,
                            svymean)

# CALCULATE CONSUMED, INEDIBLE, WASTED AMOUNTS
allfoods_cost_consumed_bysub <- svyby(reformulate(names(price_wide_comb5) %>% str_subset("consumed")),
                             ~subgroup,
                             my_cost_svy_sub,
                             svymean)

allfoods_cost_wasted_bysub <- svyby(reformulate(names(price_wide_comb5) %>% str_subset("wasted")),
                                      ~subgroup,
                                      my_cost_svy_sub,
                                      svymean)

allfoods_cost_inedible_bysub <- svyby(reformulate(names(price_wide_comb5) %>% str_subset("inedible")),
                                    ~subgroup,
                                    my_cost_svy_sub,
                                    svymean)

# CLEANING FUNCTION

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
                                       values_to = paste0(y, "_se"))
  
  my_mean_long <- my_mean %>% pivot_longer(cols = !subgroup,
                                           names_to = "food",
                                           values_to = paste0(y, "_mean"))
  
  # join
  allfoods_bysub_long <- left_join(my_mean_long, my_se_long, by = c("subgroup", "food"))
  
  # need to fix names
  dat <- allfoods_bysub_long %>% 
    #mutate(food = gsub(paste0(y, "_impact_avg_"), "", food)) %>% 
    mutate(food_type = case_when(grepl("fah", food) ~ "Grocery",
                                 grepl("fafh", food) ~ "Non-Grocery",
                                 grepl("total", food) ~ "Total")) %>% 
    mutate(food = gsub(".*_sum_", "", food))
  
  print(dat)
  
}

# APPLY FUNCTION
cost_dat <- clean_func(x = allfoods_cost_bysub, y = "price")

cost_dat1 <- 
  cost_dat %>% mutate(intake_type = case_when(grepl("Consumed", food) ~ "Consumed",
                                            grepl("Wasted", food) ~ "Wasted",
                                            grepl("Inedible", food) ~ "Inedible")) %>% 
  mutate(food = gsub("Consumed_|Wasted_|Inedible_", "", food))
  
cost_dat2 <-
  cost_dat1 %>% pivot_wider(names_from = intake_type,
                          values_from = c(price_mean, price_se)) %>% 
  arrange(subgroup, food, food_type)


cost_consumed_dat <- clean_func(x = allfoods_cost_consumed_bysub, y = "consumed")
cost_wasted_dat <- clean_func(x = allfoods_cost_wasted_bysub, y = "wasted")
cost_inedible_dat <- clean_func(x = allfoods_cost_inedible_bysub, y = "inedible")

cost_intake_dat <- left_join(cost_consumed_dat, cost_wasted_dat, by = c("subgroup", "food", "food_type")) %>% 
  left_join(cost_inedible_dat, by = c("subgroup", "food", "food_type"))

# join
cost_final_dat <- 
  left_join(cost_dat2, cost_intake_dat, by = c("subgroup", "food", "food_type")) %>% 
  rename(fndds_consumed_mean = consumed_mean,
         fndds_consumed_se = consumed_se,
         fndds_wasted_mean = wasted_mean,
         fndds_wasted_se = wasted_se,
         fndds_inedible_mean = inedible_mean,
         fndds_inedible_se = inedible_se)

# CALCULATE IMPACT FACTORS PER 100 GRAMS AND PER 1 SERVING (DGA)

# first, import conversion units
units <- read_csv("in/Environmental impact (Brooke)/raw data/unit_conversions_091323_FINAL.csv") %>% 
  select(Food_group, Conversion_to_grams)

# merge with units
cost_final_dat1 <- cost_final_dat %>% 
  left_join(units, by = c("food" = "Food_group"))

cost_final_dat2 <- cost_final_dat1 %>% 
  rowwise() %>% 
  mutate(costper100gram_consumed = ifelse(fndds_consumed_mean == 0, 0, (price_mean_Consumed / fndds_consumed_mean) * 100),
         costperDGA_consumed = costper100gram_consumed * (Conversion_to_grams / 100),
         
         costper100gram_wasted = ifelse(fndds_wasted_mean == 0, 0, (price_mean_Wasted / fndds_wasted_mean) * 100),
         costperDGA_wasted = costper100gram_wasted * (Conversion_to_grams / 100),
         
         costper100gram_inedible = ifelse(fndds_inedible_mean == 0, 0, (price_mean_Inedible / fndds_inedible_mean) * 100),
         costperDGA_inedible = costper100gram_inedible * (Conversion_to_grams / 100)) 

# CALCULATE ENVIRONMENTAL IMPACT, BY FOOD, BY SUBGROUP -----

# join
enviro_wide6 <- full_join(enviro_wide5, subgroup_dat, by = c("seqn" = "SEQN"))

# how many people have missing data but inanalysis=1? none
# enviro_wide6 %>% filter(is.na(intake_sum_dairy) & inAnalysis == TRUE)
# enviro_wide6 %>% filter(is.na(ghg_sum_dairy) & inAnalysis == TRUE) 

# Define survey design for ghg dataset 
my_enviro_svy <- svydesign(data=enviro_wide6, 
                           id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                           strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                           weights=~wtnew, # New sample weight
                           nest=TRUE)

# Create a survey design object for the subset of interest 
my_enviro_svy_sub <- subset(my_enviro_svy, inAnalysis==1)

# CALCULATE GHG IMPACT
allfoods_ghg_bysub <- svyby(reformulate(names(enviro_wide6) %>% str_subset("ghg")),
                            ~subgroup,
                            my_enviro_svy_sub,
                            svymean)

# CALCULATE CED IMPACT
allfoods_ced_bysub <- svyby(reformulate(names(enviro_wide6) %>% str_subset("ced")),
                            ~subgroup,
                            my_enviro_svy_sub,
                            svymean)

# CALCULATE CONSUMED, INEDIBLE, WASTED AMOUNTS
allfoods_enviro_consumed_bysub <- svyby(reformulate(names(enviro_wide6) %>% str_subset("consumed")),
                                    ~subgroup,
                                    my_enviro_svy_sub,
                                    svymean)

allfoods_enviro_wasted_bysub <- svyby(reformulate(names(enviro_wide6) %>% str_subset("wasted")),
                                        ~subgroup,
                                        my_enviro_svy_sub,
                                        svymean)

allfoods_enviro_inedible_bysub <- svyby(reformulate(names(enviro_wide6) %>% str_subset("inedible")),
                                      ~subgroup,
                                      my_enviro_svy_sub,
                                      svymean)

# APPLY FUNCTION
ghg_dat <- clean_func(x = allfoods_ghg_bysub, y = "ghg") %>% select(-food_type)
ced_dat <- clean_func(x = allfoods_ced_bysub, y = "ced") %>% select(-food_type)

enviro_dat <- left_join(ghg_dat, ced_dat, by = c("subgroup", "food")) 


enviro_dat1 <- 
  enviro_dat %>% mutate(intake_type = case_when(grepl("Consumed", food) ~ "Consumed",
                                              grepl("Wasted", food) ~ "Wasted",
                                              grepl("Inedible", food) ~ "Inedible")) %>% 
  mutate(food = gsub("Consumed_|Wasted_|Inedible_", "", food))

enviro_dat2 <-
  enviro_dat1 %>% pivot_wider(names_from = intake_type,
                            values_from = c(ghg_mean, ghg_se, ced_mean, ced_se)) %>% 
  arrange(subgroup, food)

enviro_consumed_dat <- clean_func(x = allfoods_enviro_consumed_bysub, y = "consumed") %>% select(-food_type)
enviro_wasted_dat <- clean_func(x = allfoods_enviro_wasted_bysub, y = "wasted") %>% select(-food_type)
enviro_inedible_dat <- clean_func(x = allfoods_enviro_inedible_bysub, y = "inedible") %>% select(-food_type)

enviro_intake_dat <- left_join(enviro_consumed_dat, enviro_wasted_dat, by = c("subgroup", "food")) %>% 
  left_join(enviro_inedible_dat, by = c("subgroup", "food"))


# join
enviro_final_dat <- 
  left_join(enviro_dat2, enviro_intake_dat, by = c("subgroup", "food")) %>% 
  rename(fcid_consumed_mean = consumed_mean,
         fcid_consumed_se = consumed_se,
         fcid_wasted_mean = wasted_mean,
         fcid_wasted_se = wasted_se,
         fcid_inedible_mean = inedible_mean,
         fcid_inedible_se = inedible_se)

# CALCULATE IMPACT FACTORS PER 100 GRAMS AND PER 1 SERVING (DGA)

# merge with units
enviro_final_dat1 <- enviro_final_dat %>% 
  left_join(units, by = c("food" = "Food_group"))

enviro_final_dat2 <- enviro_final_dat1 %>% 
  rowwise() %>% 
  mutate(#GHG
         GHGper100gram_consumed = ifelse(fcid_consumed_mean == 0, 0, (ghg_mean_Consumed / fcid_consumed_mean) * 100),
         GHGperDGA_consumed = GHGper100gram_consumed * (Conversion_to_grams / 100),
         
         GHGper100gram_inedible = ifelse(fcid_inedible_mean == 0, 0, (ghg_mean_Inedible / fcid_inedible_mean) * 100),
         GHGperDGA_inedible = GHGper100gram_inedible * (Conversion_to_grams / 100),
         
         GHGper100gram_wasted = ifelse(fcid_wasted_mean == 0, 0, (ghg_mean_Wasted / fcid_wasted_mean) * 100),
         GHGperDGA_wasted = GHGper100gram_wasted * (Conversion_to_grams / 100),
         
         #CED
         CEDper100gram_consumed = ifelse(fcid_consumed_mean == 0, 0, (ced_mean_Consumed / fcid_consumed_mean) * 100),
         CEDperDGA_consumed = CEDper100gram_consumed * (Conversion_to_grams / 100),
         
         CEDper100gram_inedible = ifelse(fcid_inedible_mean == 0, 0, (ced_mean_Inedible / fcid_inedible_mean) * 100),
         CEDperDGA_inedible = CEDper100gram_inedible * (Conversion_to_grams / 100),
         
         CEDper100gram_wasted = ifelse(fcid_wasted_mean == 0, 0, (ced_mean_Wasted / fcid_wasted_mean) * 100),
         CEDperDGA_wasted = CEDper100gram_wasted * (Conversion_to_grams / 100)) %>% 
  select(-Conversion_to_grams)

# MERGE COST AND ENVIRO DATASETS

all_impacts <- full_join(enviro_final_dat2, cost_final_dat2, by = c("subgroup", "food")) %>% 
  relocate(food_type, .after = food) %>% 
  arrange(subgroup, food, food_type) %>% 
  filter(!(food %in% c("babyfood", "coffee_tea", "other", "water")))

# EXPORT
# all impacts
write_csv(all_impacts, "in/Environmental impact (Brooke)/clean data/Impacts_total_BROOKE_100623.csv")

# rm(list = ls())

# THEN MATCH MEGA DATA FILE (Edit Fred code)
