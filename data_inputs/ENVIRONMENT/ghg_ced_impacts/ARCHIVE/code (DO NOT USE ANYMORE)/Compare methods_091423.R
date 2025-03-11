# Compare methods
# Author: Brooke Bell
# Date: 09-14-23

rm(list = ls())

options(scipen=999)

library(tidyverse)
library(readxl)
library(survey)

# ENVIRONMENT -----

a <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_enviro_LU_091423.csv") %>% 
  select(food_group, subgroup, GHGperDGA, CEDperDGA) %>%
  rename(GHGperDGA_method1 = GHGperDGA,
         CEDperDGA_method1 = CEDperDGA)

b <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_enviro_BROOKE_091423.csv") %>% 
  select(food, subgroup, GHGperDGA, CEDperDGA) %>% 
  rename(GHGperDGA_method2 = GHGperDGA,
         CEDperDGA_method2 = CEDperDGA)

my_join <- left_join(a, b, by = c("subgroup", "food_group" = "food"))

my_join1 <- my_join %>% 
  mutate(perc_diff_GHG = ((GHGperDGA_method2 - GHGperDGA_method1) / GHGperDGA_method1) * 100,
         diff_GHG = GHGperDGA_method2 - GHGperDGA_method1,
         perc_diff_CED = ((CEDperDGA_method2 - CEDperDGA_method1) / CEDperDGA_method1) * 100,
         diff_CED = CEDperDGA_method2 - CEDperDGA_method1) %>% 
  relocate(c(GHGperDGA_method2, diff_GHG, perc_diff_GHG), .after = GHGperDGA_method1) %>% 
  relocate(diff_CED, .after = CEDperDGA_method2)

write_csv(my_join1, "in/Environmental impact (Brooke)/clean data/Method_comparison_enviro_091423.csv")

ghg_hist <- my_join1 %>% 
  ggplot(mapping = aes(x=perc_diff_GHG)) +
  geom_histogram(bins = 15) +
  xlab("% Difference in GHG impact factor (CO2-eq/DGA unit)")

ghg_hist

ced_hist <- my_join1 %>% 
  ggplot(mapping = aes(x=perc_diff_CED)) +
  geom_histogram(bins = 15) +
  xlab("% Difference in CED impact factor (MJ/DGA unit)")

ced_hist

# PRICE -----

c <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_price_LU_091423.csv") %>% 
  select(food_group, costperDGA) %>% 
  rename(costperDGA_method1 = costperDGA)

d <- read_csv("in/Environmental impact (Brooke)/clean data/Impacts_price_BROOKE_091423.csv") %>% 
  select(food, subgroup, costperDGA) %>% 
  rename(costperDGA_method2 = costperDGA)

cost_join <- left_join(d, c, by = c("food" = "food_group")) %>% 
  filter(food != "sat_fat")

# calculate difference

cost_join1 <- cost_join %>% 
  mutate(diff_cost = costperDGA_method2 - costperDGA_method1,
         perc_diff_cost = ((costperDGA_method2 - costperDGA_method1) / costperDGA_method1) * 100) %>% 
  relocate(costperDGA_method2, .after = costperDGA_method1)

write_csv(cost_join1, "in/Environmental impact (Brooke)/clean data/Method_comparison_price_091423.csv")

cost_hist <- cost_join1 %>% 
  ggplot(mapping = aes(x=perc_diff_cost)) +
  geom_histogram() +
  xlab("% Difference in Cost impact factor ($/DGA unit)")

cost_hist

library(cowplot)

all_hist <- plot_grid(ghg_hist, ced_hist, cost_hist)

ggsave("in/Environmental impact (Brooke)/clean data/Method_comparison_histograms.png",
       plot = all_hist)


