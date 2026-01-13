# Clean up FAH FAFH results 
# Author: Brooke Bell
# Date: 7-6-23

rm(list=ls())

library(tidyverse)
library(readxl)

# import
fafh_results <- read_xlsx("in/FAH FAFH ratio/results/Results_bmb_updated_07-06-23.xlsx",
          sheet = "Byfood_amt_away_fap")

fah_results <- read_xlsx("in/FAH FAFH ratio/results/Results_bmb_updated_07-06-23.xlsx",
                          sheet = "Byfood_amt_home_fap")

# calculate results per 100 grams
fafh_results1 <- fafh_results %>% mutate(mean_100g_FAFH = mean * 100) %>% 
  select(food, mean_100g_FAFH)

fah_results1 <- fah_results %>% mutate(mean_100g_FAH = mean * 100) %>% 
  select(food, mean_100g_FAH)

# import variable mapping
var_map <- read_csv("in/FAH FAFH ratio/Variable mapping.csv")

# combine
comb <- var_map %>% 
  left_join(fah_results1, by = c("FAH_var" = "food"))

comb1 <- comb %>% 
  left_join(fafh_results1, by = c("FAFH_var" = "food")) %>% 
  select(-c(FAH_var, FAFH_var))

# calculate ratio
comb2 <- comb1 %>% mutate(ratio_FAFH_FAH = mean_100g_FAFH / mean_100g_FAH)

write_csv(comb2, "in/FAH FAFH ratio/results/fafh_fah_ratio_clean_07-06-23.csv")
