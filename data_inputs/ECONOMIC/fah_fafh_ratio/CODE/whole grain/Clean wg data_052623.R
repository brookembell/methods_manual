# clean whole/refined grains dataset
# 5-17-2023

rm(list = ls())

library(haven)
library(tidyverse)

# whole grain vs. refined grain
wg <- read_sas("in/FAH FAFH ratio/Brooke/whole grain/dr1iff_usda_dga_0318.sas7bdat")

wg1 <- wg %>% select(food_code, USDA_DGA) %>% distinct()

wg2 <- wg1 %>% filter(USDA_DGA %in% c(1, 0))

wg3 <- wg2 %>% rename(whole_grain_yes = USDA_DGA,
                      foodcode = food_code) %>% 
  mutate(foodcode = as.character(foodcode))

wg3

wg_ids <- wg3$foodcode %>% unlist()

# check if duplicates
foo <- (unique(wg3$foodcode)) # 3905

# which foodcodes show up more than once?

foo[!(wg_ids %in% foo)]

wg_ids[!(foo %in% wg_ids)]


#export
write_csv(wg3, "in/FAH FAFH ratio/Brooke/whole grain/whole_grain_indicator_052623.csv")
write_dta(wg3, "in/FAH FAFH ratio/Brooke/whole grain/whole_grain_indicator_052623.dta")


# MERGE WITH FAH & FAFH DATASETS -----

# 1) food at home
fah <- read_stata("in/FAH FAFH ratio/Brooke/faps_fahnutrients.dta")

# change to character
fah1 <- fah %>% mutate(foodcode = as.character(foodcode))

# remove row if foodcode is missing
fah2 <- fah1 %>% filter(!(is.na(foodcode)))

# handle ids
# wg_ids <- wg3 %>% select(foodcode) %>% unlist() %>% as.vector()
# 
# fah_ids <- fah %>% select(foodcode) %>% unlist() %>% as.vector()
# 
# new_ids <- wg_ids[wg_ids %in% fah_ids]
# 
# wg4 <- wg3 %>% filter(foodcode %in% new_ids)


# join
fah_join <- left_join(fah2, wg3, by = "foodcode")

fah_join %>% select(foodcode, whole_grain_yes) %>% View()


# check
fah_join %>% select(foodcode, foodcodetype, whole_grain_yes) %>% View()

# export
write_dta(fah_join, "in/FAH FAFH ratio/Brooke/faps_fahnutrients_bmb.dta")

# 2) food away from home
fafh <- read_stata("in/FAH FAFH ratio/Brooke/faps_fafhnutrient_puf.dta")

# join
fafh_join <- left_join(fafh, wg3, by = "foodcode")




