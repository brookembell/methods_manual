# CALCULATE SSB VARIABLE
# AUTHOR: BROOKE BELL
# DATE: 02-03-25

# STEP 0: SET-UP -----

rm(list=ls())

# load packages
library(tidyverse)
library(readxl)
library(haven)

# STEP 1: IMPORT DATASETS -----

wweia1516 <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA1516_foodcat_FNDDS.xlsx")
wweia1718 <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA1718_foodcat_FNDDS.xlsx")

map <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA category codes.xlsx",
                 sheet = "Mapping")

gl1 <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA category codes.xlsx",
                 sheet = "GL1")

gl2 <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA category codes.xlsx",
                 sheet = "GL2")

gl2b <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA category codes.xlsx",
                  sheet = "GL2b")

gl3 <- read_xlsx("in/ALL PILLARS/Dietary intake/raw data/WWEIA category codes.xlsx",
                 sheet = "GL3")

# join

map_join <- 
  map %>% 
  left_join(gl1) %>% 
  left_join(gl2) %>% 
  left_join(gl2b) %>% 
  left_join(gl3)

# merge with wweia datasets

wweia1516_1 <- wweia1516 %>% left_join(map_join, by = "category_number")
wweia1718_1 <- wweia1718 %>% left_join(map_join, by = "category_number")

# read in fped datasets

fped1516 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_1516.sas7bdat")
fped1718 <- read_sas("in/ALL PILLARS/Dietary intake/raw data/fped_1718.sas7bdat")

# fped1516$ADD_SUGARS

fped1516_1 <- 
  fped1516 %>% 
  rename(food_code = FOODCODE) %>% 
  # convert tsp to gram using 1 tsp=4.2g sugar
  mutate(add_sugars_g = ADD_SUGARS * 4.2) %>%
  select(food_code, add_sugars_g) 

fped1718_1 <- 
  fped1718 %>% 
  rename(food_code = FOODCODE) %>% 
  # convert tsp to gram using 1 tsp=4.2g sugar
  mutate(add_sugars_g = ADD_SUGARS * 4.2) %>%
  select(food_code, add_sugars_g)   

# read in nhanes individual food data

foods_day1 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day1_clean.rds")
foods_day2 <- read_rds("in/ALL PILLARS/Dietary intake/clean data/foods_day2_clean.rds")

# split up
nhanes1516_day1 <- foods_day1 %>% filter(nhanes_cycle == "2015-2016")
nhanes1718_day1 <- foods_day1 %>% filter(nhanes_cycle == "2017-2018")

nhanes1516_day2 <- foods_day2 %>% filter(nhanes_cycle == "2015-2016")
nhanes1718_day2 <- foods_day2 %>% filter(nhanes_cycle == "2017-2018")

# merge fped and wweia datasets

foo1516 <- left_join(wweia1516_1, fped1516_1, by = "food_code")
foo1718 <- left_join(wweia1718_1, fped1718_1, by = "food_code")

# merge foo with nhanes

nhanes1516_day1_join <- left_join(nhanes1516_day1, foo1516, by = c("DR1IFDCD" = "food_code"))
nhanes1516_day2_join <- left_join(nhanes1516_day2, foo1516, by = c("DR2IFDCD" = "food_code"))

nhanes1718_day1_join <- left_join(nhanes1718_day1, foo1718, by = c("DR1IFDCD" = "food_code"))
nhanes1718_day2_join <- left_join(nhanes1718_day2, foo1718, by = c("DR2IFDCD" = "food_code"))

# work on day1 first

nhanes1516_day1_join_1 <-
  nhanes1516_day1_join %>% 
  mutate(ssb = ifelse(add_sugars_g >= 5 & between(GL1, 151, 156), 1, 0), # if 1 serving has >= 5 grams of add sugar, then ssb=1
         GL3 = ifelse(GL3 == 322 & ssb == 0, 321, GL3), # diet drink
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 1, 328, GL3), # sweetened coffee/tea
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 0, 329, GL4)) # non-sweetened coffee/tea

nhanes1718_day1_join_1 <-
  nhanes1718_day1_join %>% 
  mutate(ssb = ifelse(add_sugars_g >= 5 & between(GL1, 151, 156), 1, 0),
         GL3 = ifelse(GL3 == 322 & ssb == 0, 321, GL3), # diet drink
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 1, 328, GL3), # sweetened coffee/tea
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 0, 329, GL4)) # non-sweetened coffee/tea


# only select necessary vars
nhanes1516_day1_join_2 <- nhanes1516_day1_join_1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DESCRIPTION, DR1IGRMS, ssb)

nhanes15718_day1_join_2 <- nhanes1718_day1_join_1 %>% select(SEQN, DR1ILINE, DR1IFDCD, DESCRIPTION, DR1IGRMS, ssb)

day1_final <- rbind(nhanes1516_day1_join_2, nhanes15718_day1_join_2)

# now work on day2

nhanes1516_day2_join_1 <-
  nhanes1516_day2_join %>% 
  mutate(ssb = ifelse(add_sugars_g >= 5 & between(GL1, 151, 156), 1, 0),
         GL3 = ifelse(GL3 == 322 & ssb == 0, 321, GL3), # diet drink
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 1, 328, GL3), # sweetened coffee/tea
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 0, 329, GL4)) # non-sweetened coffee/tea

nhanes1718_day2_join_1 <-
  nhanes1718_day2_join %>% 
  mutate(ssb = ifelse(add_sugars_g >= 5 & between(GL1, 151, 156), 1, 0),
         GL3 = ifelse(GL3 == 322 & ssb == 0, 321, GL3), # diet drink
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 1, 328, GL3), # sweetened coffee/tea
         GL4 = ifelse((category_number == 7302 | category_number == 7304) & ssb == 0, 329, GL4)) # non-sweetened coffee/tea


# only select necessary vars
nhanes1516_day2_join_2 <- nhanes1516_day2_join_1 %>% select(SEQN, DR2ILINE, DR2IFDCD, DESCRIPTION, DR2IGRMS, ssb)

nhanes1718_day2_join_2 <- nhanes1718_day2_join_1 %>% select(SEQN, DR2ILINE, DR2IFDCD, DESCRIPTION, DR2IGRMS, ssb)

day2_final <- rbind(nhanes1516_day2_join_2, nhanes1718_day2_join_2)

# export these datasets to use later 
write_rds(day1_final, "in/ALL PILLARS/Dietary intake/clean data/foods_day1_ssb.rds")
write_rds(day2_final, "in/ALL PILLARS/Dietary intake/clean data/foods_day2_ssb.rds")

# calculate ssb intake (grams) for day 1 and day 2

# day 1

ssb_day1 <- day1_final %>% 
  mutate(ssb = as.character(ssb)) %>% 
  group_by(SEQN, ssb) %>% 
  summarise(grams = sum(DR1IGRMS)) %>% 
  arrange(SEQN, ssb)

ssb_day1

ssb_day1_wide <-
  pivot_wider(ssb_day1,
            id_cols = SEQN,
            names_from = ssb,
            values_from = grams,
            names_prefix = "ssb")

ssb_day1_wide1 <- 
  ssb_day1_wide %>% 
  mutate(ssb1 = ifelse(!is.na(ssb0) & is.na(ssb1), 0, ssb1)) %>% 
  select(SEQN, ssb1) %>% 
  rename(ssb_1 = ssb1)

# day 2

ssb_day2 <- day2_final %>% 
  mutate(ssb = as.character(ssb)) %>% 
  group_by(SEQN, ssb) %>% 
  summarise(grams = sum(DR2IGRMS)) %>% 
  arrange(SEQN, ssb)

ssb_day2

ssb_day2_wide <-
  pivot_wider(ssb_day2,
              id_cols = SEQN,
              names_from = ssb,
              values_from = grams,
              names_prefix = "ssb")

ssb_day2_wide1 <- 
  ssb_day2_wide %>% 
  mutate(ssb1 = ifelse(!is.na(ssb0) & is.na(ssb1), 0, ssb1)) %>% 
  select(SEQN, ssb1) %>% 
  rename(ssb_2 = ssb1)

ssb_bothdays <- full_join(ssb_day1_wide1, ssb_day2_wide1, by = "SEQN")

# are there any where both are missing? no
ssb_bothdays %>% filter(is.na(ssb_1) & is.na(ssb_2))

# calculate day1/day2 ssb intake average
ssb_bothdays_1 <-
  ssb_bothdays %>%
  rowwise() %>%
  mutate(ssb = mean(c(ssb_1, ssb_2), na.rm=TRUE))

# get rid of NaN
ssb_bothdays_1[ssb_bothdays_1 == "NaN"] <- NA

# read in nhanes dataset
nhanes <- read_rds("in/ALL PILLARS/Dietary intake/clean data/nhanes1518_clean.rds")

nhanes_1 <- left_join(nhanes, ssb_bothdays_1, by = "SEQN")

# nhanes_2 <- nhanes_1 %>% mutate(ssb = replace_na(ssb, 0),
#                                 ssb_1 = replace_na(ssb_1, 0),
#                                 ssb_2 = replace_na(ssb_2, 0))

# which ones where ssb (in grams) is more than 0 but lower than 10 grams? (maybe a sip?)
nhanes_1 %>% filter(ssb_1 > 0 & ssb_1 < 11) %>% View()
nhanes_1 %>% filter(ssb_2 > 0 & ssb_2 < 11) %>% View()

# look at just one person - 84956

foods_day2 %>% filter(SEQN == 84956) %>% View()

foods_day1 %>% filter(SEQN == 84997) %>% View()

# it looks fine

write_rds(nhanes_1,
          "in/ALL PILLARS/Dietary intake/clean data/nhanes1518_incl_ssb_clean.rds")

