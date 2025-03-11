# Try to figure out red and processed meat 
# Author: Brooke Bell
# Date: 12-3-23

rm(list = ls())

library(tidyverse)
library(readxl)
library(survey)

options(scipen = 100)

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

# STRATEGY 1: Calculate red meat and poultry intake at FCID-level ------

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

# import fcid food categories
food_cats <- read_csv("in/ENVIRONMENT PILLAR/FCID to diet/data/FCID_food_category.csv") %>% 
  select(`Food category`, `Meat category`, `FCID ingredient code`) %>% 
  rename(food_group = `Food category`,
         meat_group = `Meat category`,
         fcidcode = `FCID ingredient code`)


# merge with data
both_days3 <- left_join(both_days2, food_cats, by = "fcidcode")

# calculate consumption of fcid ingredients
both_days4 <- both_days3 %>% 
  rowwise() %>% 
  mutate(consumed_fcid = grams * (wt / 100))

# summarise meat intake
meat_sum <- both_days4 %>% 
  ungroup() %>% 
  group_by(seqn, line, foodcode, dayrec, meat_group) %>% 
  summarise(meat_consumed = sum(consumed_fcid))

meat_sum1 <- meat_sum %>% filter(meat_group != "None") %>% 
  arrange(seqn, dayrec, line, foodcode) %>% 
  mutate(meat_consumed_oz = ifelse(meat_group == "Red meat", meat_consumed / 31, meat_consumed / 29))
  

# long to wide (foodcode-level)
meat_wide_foodcode <- meat_sum1 %>% 
  pivot_wider(id_cols = c(seqn, dayrec, foodcode, line),
              names_from = meat_group,
              values_from = meat_consumed_oz)

meat_wide_foodcode1 <- meat_wide_foodcode %>% 
  rename(pf_redm_new = `Red meat`,
         pf_poultry_new = Poultry) %>% 
  replace(is.na(.), 0)
  
# export
write_csv(meat_wide_foodcode1, "in/ALL PILLARS/Dietary intake/clean data/meat_intake_foodcode-level_120523.csv")

  
# summarize at the day level
meat_wide_seqn <- meat_wide_foodcode1 %>% 
  ungroup() %>% 
  group_by(seqn, dayrec) %>% 
  summarise(pf_poultry_new = sum(pf_poultry_new),
            pf_redm_new = sum(pf_redm_new))

# long to wide
meat_wide_seqn1 <- pivot_wider(meat_wide_seqn,
            id_cols = seqn,
            names_from = dayrec,
            values_from = c(pf_redm_new, pf_poultry_new))

# export
write_csv(meat_wide_seqn1, "in/ALL PILLARS/Dietary intake/clean data/meat_intake_seqn-level_120523.csv")


# STRATEGY 2: Calculate processed meat ratio and apply to red meat and poultry intake ------

# just filter processed meat
pm <- both_days %>% filter(pf_pm == pf_meat & pf_pm > 0)

pm %>% filter(pf_redm == 0 & pf_poultry == 0) %>% View() #majority

# import fndds-food mapping
fndds_groups <- read_csv("in/ENVIRONMENT PILLAR/Environmental impact/raw data/Food_to_FNDDS_mapping_detailed_09-04-23_v2.csv")

# just meat
fndds_meat <- fndds_groups %>% filter(Foodgroup %in% c("pf_redm", "pf_poultry", "pf_pm")) %>% 
  arrange(Foodgroup)


# pm %>% filter(str_detect(foodcode, "^25")) %>% View()

pm_foodcodes <- pm %>% filter(str_detect(foodcode, "^25")) %>% select(foodcode, description) %>% distinct()

# export
# write_csv(pm_foodcodes, "in/ALL PILLARS/Dietary intake/other data/processed_meat_foodcodes_120523.csv")

# import
pm_mapped <- read_xlsx("in/ALL PILLARS/Dietary intake/other data/processed_meat_foodcodes_120523_mapped.xlsx")

# join
# pm1 <- left_join(pm, pm_mapped, by = c("foodcode", "description"))
# 
# pm1 %>% filter(str_detect(foodcode, "^28500050")) %>% View()



#pm_new <- 
  # pm %>% 
  # mutate(fndds_food_group = case_when(
  #                                   str_detect(foodcode, "^20|^21|^22|^23|^2711|^2712|^2713|^2716|^2721|^2722|^2723|^2726|^2731|^2732|^2733|^2736|^2741|^2742|^2743|^2746|^2750|^2751|^2752|^2756|^2810|^2811|^2816|^2831") ~ "pf_redm",
  #                                   str_detect(foodcode, "^24|^2714|^2724|^2734|^2744|^2754|^2814|^2834") ~ "pf_poultry",
  #                                   str_detect(foodcode, "^25") ~ "pf_pm",
  # 
  #                                   foodcode %in% c("28500000", "28500050", "28500080", "28501110", "28510010", "89901006") ~ "pf_poultry",
  #                                   foodcode %in% c("20000000", "28500010", "28500040", "28500070", "28501010", "28520000", "28520010", "89901000", "89901002", "89901004", "89902100") ~ "pf_redm")) %>% 
  #   View()

    
pm1 <- full_join(pm, map1, by = "foodcode")   

pm2 <- left_join(pm1, food_cats, by = "fcidcode")

# calculate consumption of fcid ingredients
pm3 <- pm2 %>% 
  rowwise() %>% 
  mutate(consumed_fcid = grams * (wt / 100))


# summarise
pm_sum <- pm3 %>% 
  group_by(meat_group) %>% 
  summarise(consumed = sum(consumed_fcid, na.rm = TRUE)) %>% 
  filter(meat_group %in% c("Poultry", "Red meat"))

pm_sum

568928 / (149686 + 568928)







# # long to wide
# pm_wide <- pm_sum %>% pivot_wider(id_cols = c(seqn, dayrec),
#                        names_from = meat_group,
#                        values_from = consumed) %>% 
#   rename(pf_redm = `Red meat`,
#          pf_poultry = Poultry)  %>% 
#   filter(!(is.na(seqn)))
# 
# 
# pm_wide %>% 
#   pivot_wider(id_cols = seqn,
#               names_from = dayrec,
#               values_from = c(pf_redm, pf_poultry))
