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
                      foodcode = food_code)

#export
write_csv(wg3, "in/FAH FAFH ratio/Brooke/whole grain/whole_grain_indicator_052623.csv")






# IGNORE THIS FOR NOW -----

# food at home
fah <- read_stata("in/FAH FAFH ratio/Brooke/faps_fahnutrients.dta")

fah1 <- fah %>% mutate(foodcode_chr = as.character(foodcode))

fah2 <- fah1 %>% filter(str_starts(foodcode_chr, "51|52|53|54|55|56|57") & foodcodetype == 1)

# join
blah <- left_join(fah2, wg3, by = c("foodcode" = "food_code"))

# how many missing?
sum(is.na(blah$whole_grain_yes))

blah %>% 
  select(foodcode, whole_grain_yes, usdadescmain) %>% 
  filter(is.na(whole_grain_yes)) %>% 
  distinct() %>% View()

#only 20 are missing, which I could technically manually code...will wait for now





