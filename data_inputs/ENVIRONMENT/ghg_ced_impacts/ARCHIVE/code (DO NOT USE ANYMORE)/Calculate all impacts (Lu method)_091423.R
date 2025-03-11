# Calculate environmental impact and cost at food level
# LU METHOD
# Author: Brooke Bell
# Date: 09-13-23

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

# MAPPING FROM FNDDS FOODCODE TO FCID CODE -----

# import 
map <- read_csv("in/Environmental impact (Brooke)/raw data/FCID_0118_LASTING.csv")

map1 <- map %>% select(foodcode, fcidcode, fcid_desc, wt)

# combine with food data
both_days5 <- full_join(both_days, map1, by = "foodcode")

# remove if missing SEQN - foodcodes that no one ate
both_days5 %>% filter(is.na(grams)) %>% View()

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
both_days9 <- both_days8 %>% filter(Foodgroup_FCID %in% diet_factors | is.na(Foodgroup_FCID))

# which FNDDS foodcodes have missing FCID food group?
both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% View()

both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct() %>% View()

# export
# no_fcids <- both_days9 %>% filter(is.na(Foodgroup_FCID)) %>% select(foodcode, description) %>% distinct()
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

# calculate consumed_amt_g, inedible_amt_g, wasted_amt_g, total_amt_g
both_days13 <- both_days12 %>% 
  mutate(Commodity_wt1 = grams * wt / 100,
         wasted_amt_g = Commodity_wt1 * waste_coef,
         Commodity_wt1_adj = Commodity_wt1 + wasted_amt_g)

# how many rows have missing consumed_amt? only 10 rows total
both_days13 %>% filter(is.na(Commodity_wt1)) %>% View()

# export
# no_waste <- both_days14 %>% filter(is.na(waste_coef)) %>% select(fcidcode, fcid_desc) %>% distinct()
# write_csv(no_waste, "in/Environmental impact (Brooke)/missing data/Missing waste coefficients.csv")

# clear out global environment
rm(list=setdiff(ls(), "both_days13"))

# THIS IS WHERE MAJOR DIFFERENCES OCCUR IN LU'S METHOD -----

# first, we have to calculate person-level intake of each FCID across 2 days
# Lu didn't do this initially bc she only used 1 day of intake
dat <- both_days13 %>% 
  group_by(seqn, dayrec, fcidcode) %>% 
  mutate(Commodity_wt1_sum = sum(Commodity_wt1_adj)) %>% 
  ungroup()

# check
dat %>% arrange(seqn, dayrec, fcidcode) %>% View()

# remove if missing seqn
dat1 <- dat %>% filter(!(is.na(seqn)))

dat2 <- dat1 %>% select(seqn, dayrec, fcidcode, fcid_desc, Commodity_wt1_sum) %>% distinct() 

# transform to wide
dat_wide <- pivot_wider(dat2, 
                        names_from = dayrec,
                        values_from = Commodity_wt1_sum)

dat_wide %>% filter(is.na(fcid_desc))

# STEP 3: Summarize the total commodity weights in grams 
# for each FCID food code for each individual in “Commodity_wt2"

# replace na with 0
dat_wide1 <- dat_wide %>% 
  filter(!(is.na(fcidcode))) %>% 
  replace(is.na(.), 0) %>% 
  rowwise() %>% 
  mutate(Commodity_wt2 = mean(c(`1`, `2`)))

# rename vars
dat_wide2 <- dat_wide1 %>% rename(day1_intake = `1`,
                                  day2_intake = `2`)

# create template dataset to join with
ids <- both_days13 %>% select(seqn) %>% distinct() %>% mutate(foo = 1)

fcids <- both_days13 %>% select(fcidcode, fcid_desc) %>% distinct() %>% mutate(foo = 1)

ids_join <- full_join(ids, fcids) %>% filter(!(is.na(fcidcode)))

results <- left_join(ids_join, dat_wide2)

results1 <- results %>% 
  filter(!(is.na(seqn))) %>% 
  arrange(seqn, fcidcode) %>% 
  replace(is.na(.), 0) %>% 
  select(-foo)

# STEP 4: CACLUALTE SURVEY-WEIGHTED MEAN INTAKE IN GRAMS FOR EACH FCID CODE FOR EACH POPULATION SUBGROUP

results2 <- results1 %>% 
  mutate(fcidcode_chr = as.character(fcidcode)) %>% 
  select(-c(fcid_desc, day1_intake, day2_intake, fcidcode))

# transform to wide
results_wide <- pivot_wider(results2, 
                            names_from = fcidcode_chr,
                            values_from = Commodity_wt2,
                            names_prefix = "fcid_")

# import subgroup-seqn mapping
nhanes <- read_rds("in/Dietary intake (Brooke)/clean data/nhanes1518_adj_clean.rds")

subgroup_dat <- nhanes %>% select(SEQN, subgroup, SDMVPSU, SDMVSTRA, wtnew, inAnalysis)

results_wide1 <- full_join(results_wide, subgroup_dat, by = c("seqn" = "SEQN")) %>% replace(is.na(.), 0)

# Define survey design
my_svy <- svydesign(data=results_wide1, 
                    id=~SDMVPSU, # Masked Variance Unit Pseudo-PSU 
                    strata=~SDMVSTRA, # Masked Variance Unit Pseudo-Stratum 
                    weights=~wtnew, # New sample weight
                    nest=TRUE)

# Create a survey design object for the subset of interest 
my_svy_sub <- subset(my_svy, inAnalysis==1)

# calculate average intake for each fcid code, by subgroup
intake_bysub <- svyby(reformulate(names(results_wide1) %>% str_subset("fcid_")),
                            ~subgroup,
                            my_svy_sub,
                            svymean)

# transform to long
my_se <- intake_bysub %>% select(subgroup, starts_with("se."))
my_mean <- intake_bysub %>% select(subgroup, !starts_with("se."))

# transform both datsets to long
my_se_long <- my_se %>% pivot_longer(cols = starts_with("se."),
                                     names_to = "fcidcode",
                                     names_prefix = c("se."),
                                     values_to = "intake_se")

my_mean_long <- my_mean %>% pivot_longer(cols = !subgroup,
                                         names_to = "fcidcode",
                                         values_to = "intake_mean")

# join
allfoods_bysub_long <- left_join(my_mean_long, my_se_long, by = c("subgroup", "fcidcode"))

# need to fix names
fcid_long <- allfoods_bysub_long %>% mutate(fcidcode = gsub("fcid_", "", fcidcode)) %>% 
  rename(purchased_mean = intake_mean,
         purchased_se = intake_se)

# DATAFIELD (ENVIRO IMPACTS) -----

# STEP 5: Link the impact factor for each FCID code (unit: impact per kg) to 
# the survey-weighted mean intake of each FCID code (estimated from the steps above) 
# to calculate the impact factor for each FCID and each population subgroup

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
fcid_long1 <- left_join(fcid_long, datafield_sub, by = "fcidcode")

# any missing ghg impact factors?
fcid_long1 %>% filter(is.na(GHG_mn)) %>% View()

# create dataset to export
# missing_ghg <- 
#   fcid_long1 %>% 
#   filter(is.na(GHG_impact_g)) %>% 
#   select(fcidcode) %>% 
#   distinct()
# 
# # export 
# write_csv(missing_ghg, "in/Environmental impact (Brooke)/missing data/Missing environmental impacts.csv")

# import proxies for missing enviro data
ghg_proxies <- read_csv("in/Environmental impact (Brooke)/missing data/Resolved/Missing environmental impacts_mapped.csv")

ghg_proxies_sub <- ghg_proxies %>% 
  filter(!(is.na(fcidcode))) %>% 
  select(-c(foodcode, description, fcid_desc, proxy_notes)) %>% 
  distinct() %>% 
  mutate(fcidcode = as.character(fcidcode))

fcid_long2 <- left_join(fcid_long1, ghg_proxies_sub, by = "fcidcode") %>% mutate(proxy_fcidcode = as.character(proxy_fcidcode))

fcid_long2 %>% filter(is.na(GHG_mn)) %>% View()

# insert enviro data for fcids that were originally missing
fcid_long3 <- fcid_long2 %>% 
  rows_patch(datafield_sub %>% 
               rename(proxy_fcidcode = fcidcode), unmatched = "ignore") %>% 
  select(-c(starts_with("proxy")))

# confirm there are no more missing FCIDs
fcid_long3 %>% filter(is.na(fcidcode))  # good

# confirm there are no more missing GHG
fcid_long3 %>% filter(is.na(GHG_mn)) # good

# CALCULATE IMPACT FACTORS 

fcid_long4 <- fcid_long3 %>% mutate(CED = (CED_mn / 1000) * purchased_mean,
                                    GHG = (GHG_mn / 1000) * purchased_mean) %>% 
  arrange(fcidcode, subgroup)

fcid_long4 %>% filter(fcidcode == "101050000") %>% View()


# STEP 6: Bin FCID. Each FCID will be assigned to a food group

# import fcid-dietary factor mapping
fcid_map <- read_xlsx("in/FCID to diet/data/FCID_to_dietaryfactor_mapping_07-14-2023_final.xlsx") %>% 
  select(FCID_Code, FCID_Desc, Foodgroup) %>% 
  mutate(FCID_Code = as.character(FCID_Code))

fcid_long5 <- left_join(fcid_long4, fcid_map, by = c("fcidcode" = "FCID_Code")) %>% 
  rename(fcid_desc = FCID_Desc,
         food_group = Foodgroup) %>% 
  relocate(c(fcid_desc, food_group), .after = fcidcode)

# any  missing?
fcid_long5 %>% filter(is.na(food_group)) #none-good

# STEP 7 & 8

fcid_table <- fcid_long5 %>% 
  group_by(food_group, subgroup) %>% 
  summarise(group_purchased = sum(purchased_mean),
            group_GHG = sum(GHG),
            group_CED = sum(CED))

# STEP 9: Estimate unit impact factor for a particular food group by dividing 
# food group-specific environmental impact by food group-specific intake

# first, import conversion units

units <- read_csv("in/Environmental impact (Brooke)/raw data/unit_conversions_091323_FINAL.csv") %>% 
  select(Food_group, Conversion_to_grams)

fcid_table1 <- fcid_table %>% 
  left_join(units, by = c("food_group" = "Food_group"))

fcid_table2 <- fcid_table1 %>% 
  mutate(CEDper100gram = ifelse(group_purchased == 0, 0, (group_CED / group_purchased) * 100),
         GHGper100gram = ifelse(group_purchased == 0, 0, (group_GHG / group_purchased) * 100),
         GHGperDGA = GHGper100gram * (Conversion_to_grams / 100),
         CEDperDGA = CEDper100gram * (Conversion_to_grams / 100)) %>% 
  select(-Conversion_to_grams)

# Export
write_csv(fcid_table2, "in/Environmental impact (Brooke)/clean data/Impacts_enviro_LU_091423.csv")

# # just keep impact factors
# all_impact_factors <- fcid_table1 %>% select(subgroup, food_group, GHGper100gram, CEDper100gram)
# 
# # export
# write_csv(all_impact_factors, "in/Environmental impact (Brooke)/clean data/Impacts_per100g_enviro_LU_091323.csv")




# COST IMPACT FACTOR -----

# This was done a very difference way than above

rm(list = ls())

library(haven)
library(broom)

# IMPORT FPED
fped1516 <- read_sas("in/Dietary intake (Brooke)/raw data/fped_1516.sas7bdat") %>% mutate(nhanes1516 = 1)

fped1718 <- read_sas("in/Dietary intake (Brooke)/raw data/fped_1718.sas7bdat") %>% mutate(nhanes1516 = 0)

# combine
fped_comb <- rbind(fped1516, fped1718)


fped_comb1 <- fped_comb %>% 
  rowwise() %>% 
  rename(gr_refined = G_REFINED,
         gr_whole = G_WHOLE,
         added_sugar = ADD_SUGARS,
         fruit_juice = F_JUICE,
         fruit = F_TOTAL,
         dairy = D_TOTAL,
         veg_dg = V_DRKGR,
         veg_oth = V_OTHER,
         veg_ro = V_REDOR_TOTAL,
         veg_sta = V_STARCHY_TOTAL,
         veg_leg = V_LEGUMES,
         oil = OILS,
         pf_egg = PF_EGGS,
         pf_ns = PF_NUTSDS,
         pf_soy = PF_SOY,
         pf_leg = PF_LEGUMES,
         pf_poultry = PF_POULT,
         pf_redm = PF_MEAT,
         solid_fats = SOLID_FATS) %>% 
  mutate(fruit_exc_juice = sum(F_CITMLB, F_OTHER),
         pf_pm = sum(PF_CUREDMEAT, PF_ORGAN),
         pf_seafood = sum(PF_SEAFD_HI, PF_SEAFD_LOW),
         leg_tot = sum(pf_leg, pf_soy))

# PRICE DATA

# import price data
cost1516 <- read_xlsx("in/Food prices (Brooke)/raw data/pp_national_average_prices_andi_v.1.30.2023.xlsx",
                      sheet = "PP-NAP1516") %>%
  select(food_code, price_100gm) %>% 
  mutate(nhanes1516 = 1)


cost1718 <- read_xlsx("in/Food prices (Brooke)/raw data/pp_national_average_prices_andi_v.1.30.2023.xlsx",
                      sheet = "PP-NAP1718") %>%
  select(food_code, price_100gm) %>%
  mutate(nhanes1516 = 0)

price_comb <- rbind(cost1516, cost1718)

# combine with food data
# both_days2 <- left_join(both_days1, price_comb, by = c("foodcode" = "food_code", "nhanes1516")) %>% 
#   mutate(foodcode = as.character(foodcode))

# fped1516_2 <- left_join(fped1516_1, cost1516, by = c("FOODCODE" = "FoodCode"))

# this only includes the foodcodes where there is price data
fped1516_2 <- left_join(cost1516, fped1516_1, by = c("FoodCode" = "FOODCODE"))

fped_comb2 <- full_join(fped_comb1, price_comb, by = c("FOODCODE" = "food_code", "nhanes1516"))


# IMPORT DR1IFF (2015-2016)

dr1iff_i <- read_sas("in/Dietary intake (Brooke)/raw data/dr1iff_i.sas7bdat") %>% 
  select(DR1IFDCD, DR1IGRMS) %>% 
  rename(dr12igrms = DR1IGRMS,
         FoodCode = DR1IFDCD) %>% 
  mutate(nhanes1516 = 1)

dr2iff_i <- read_sas("in/Dietary intake (Brooke)/raw data/dr2iff_i.sas7bdat") %>% 
  select(DR2IFDCD, DR2IGRMS) %>% 
  rename(dr12igrms = DR2IGRMS,
         FoodCode = DR2IFDCD) %>% 
  mutate(nhanes1516 = 1)

# combine
dr12iff_i <- rbind(dr1iff_i, dr2iff_i)

# IMPORT DR1IFF (2017-2018)

dr1iff_j <- read_sas("in/Dietary intake (Brooke)/raw data/dr1iff_j.sas7bdat") %>% 
  select(DR1IFDCD, DR1IGRMS) %>% 
  rename(dr12igrms = DR1IGRMS,
         FoodCode = DR1IFDCD) %>% 
  mutate(nhanes1516 = 0)

dr2iff_j <- read_sas("in/Dietary intake (Brooke)/raw data/dr2iff_j.sas7bdat") %>% 
  select(DR2IFDCD, DR2IGRMS) %>% 
  rename(dr12igrms = DR2IGRMS,
         FoodCode = DR2IFDCD) %>% 
  mutate(nhanes1516 = 0)

# combine
dr12iff_j <- rbind(dr1iff_j, dr2iff_j)

# combine 1516 and 1718
dr12iff_ij <- rbind(dr12iff_i, dr12iff_j)

# summarize
FCintake <- dr12iff_ij %>% 
  group_by(FoodCode, nhanes1516) %>% 
  summarise(FCgrm = sum(dr12igrms, na.rm = TRUE))

# Combine weighting factor with FPED-PRICE data

my_table <- left_join(fped_comb2, FCintake, by = c("FOODCODE" = "FoodCode", "nhanes1516"))

# regression

# exactly matching Lu's code:
test_mod <- lm(price_100gm ~ veg_dg + veg_ro + veg_leg + veg_sta + veg_oth + fruit + gr_whole + gr_refined + 
                 dairy + pf_redm + pf_pm + pf_poultry + pf_egg + pf_seafood + pf_ns + pf_soy + oil + added_sugar + solid_fats,
             data = my_table,
             weights = FCgrm)

summary(test_mod)

# with changes to some dietary factors:
my_mod <- lm(price_100gm ~ added_sugar + dairy + gr_refined + gr_whole + oil + pf_egg + pf_ns + pf_pm + pf_poultry +
   pf_redm + pf_seafood + veg_dg + veg_oth + veg_ro + veg_sta + leg_tot + fruit_exc_juice + fruit_juice + solid_fats,
   data = my_table,
   weights = FCgrm)

summary(my_mod)

mod_results <- tidy(my_mod)

mod_results1 <- mod_results %>% rename(costperDGA = estimate,
                                       costperDGA_se = std.error,
                       food_group = term) %>% 
  select(-c(statistic, p.value)) %>% 
  filter(food_group != "(Intercept)")

# export

write_csv(mod_results1, "in/Environmental impact (Brooke)/clean data/Impacts_price_LU_091423.csv")



