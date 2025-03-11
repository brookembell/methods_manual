# Compare methods
# Author: Brooke Bell
# Date: 09-12-23

rm(list = ls())

options(scipen=999)

library(tidyverse)
library(readxl)
library(survey)

a <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_per100g_enviro_LU_091223.csv") %>% 
  select(food_group, subgroup, GHGper100gram, CEDper100gram) %>% 
  rename(GHGper100gram_method1 = GHGper100gram,
         CEDper100gram_method1 = CEDper100gram)

b <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_per100g_enviro_BROOKE_091223.csv") %>% 
  select(food, subgroup, GHGper100gram, CEDper100gram) %>% 
  rename(GHGper100gram_method2 = GHGper100gram,
         CEDper100gram_method2 = CEDper100gram)

my_join <- left_join(a, b, by = c("subgroup", "food_group" = "food"))

my_join1 <- my_join %>% 
  mutate(perc_diff_GHG = ((GHGper100gram_method2 - GHGper100gram_method1) / GHGper100gram_method1) * 100,
         perc_diff_CED = ((CEDper100gram_method2 - CEDper100gram_method1) / CEDper100gram_method1) * 100) %>% 
  relocate(c(GHGper100gram_method2, perc_diff_GHG), .after = GHGper100gram_method1)

write_csv(my_join1, "in/Environmental impact (Brooke)/clean data/Method_comparison_091223.csv")

