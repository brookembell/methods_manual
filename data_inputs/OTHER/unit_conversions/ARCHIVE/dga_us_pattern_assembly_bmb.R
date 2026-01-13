# This code is used to re-estimate the conversion factors (grams to servings) 
# for fruit (excl. juice) and vegetables (excl. starchy)
# Author: Brooke Bell

# Set up 

rm(list = ls())
library(tidyverse)

# Import data

pattern_2500_dy_us <- 
  read.csv("in/Unit conversion/Blackstone 2020/new/pattern_2500_dy_us_new_4.18.23.csv") %>% 
  filter(food_grp %in% c("veg", "fruit"))

fped_crosswalk_eat <- 
  read.csv("in/Unit conversion/Blackstone 2020/new/fped_crosswalk_eat_new_4.18.23.csv") %>% 
  select(-X) %>% 
  filter(food_grp %in% c("veg", "fruit"))

dat <- left_join(fped_crosswalk_eat, pattern_2500_dy_us, by = c("dga_subgrp_new", "food_grp"))

# JUST FOCUS ON FRUIT FIRST -----

frt <- dat %>% filter(food_grp == "fruit")

# rescale the proportion variable s.t. it sums to 1 for whole_fruit

whole_frt_prop <- frt %>% filter(dga_subgrp_new == "whole_fruit") %>% select(prop_dga_subgrp) %>% sum()
fruit_juice_prop <- frt %>% filter(dga_subgrp_new == "fruit_juice") %>% select(prop_dga_subgrp) %>% sum()

rescale_whole_frt <- 1/whole_frt_prop
rescale_frt_juice <- 1/fruit_juice_prop

whole_frt <- frt %>% 
  filter(dga_subgrp == "whole_fruit") %>% 
  mutate(new_prop = prop_dga_subgrp * rescale_num)

# proportion for fruit should =1
whole_frt %>% select(new_prop) %>% sum() #woo!

#Create diets with foods on 100g basis
whole_frt1 <- whole_frt %>% 
  mutate(ddiet_fpe_2500 = fpe_dy_2500*new_prop, #creating var for daily 2500 kcal pattern by food in fpe amounts
         ddiet_2500 = ddiet_fpe_2500*FPED_CF, #creating var for daily patterns by food in 100g amounts
         ddiet_2500_grams = ddiet_2500*100) %>% #Create gram amounts for bottom up g recommendations
  select(-fpe_dy_2500) #removing scaling vector 

#Add new column for food group proportions on a mass basis
whole_frt2 <- 
  whole_frt1 %>% 
  group_by(food_grp) %>% 
  mutate(grams_grp_tot = sum(ddiet_2500_grams), #making new column with grp gram totals
         grams_subgrp_tot = sum(ddiet_2500_grams)) #making new column with subgrp gram totals

whole_frt3 <- whole_frt2 %>% 
  select(food_grp, dga_subgrp, grams_subgrp_tot) %>% 
  distinct() %>% 
  left_join(pattern_2500_dy_us, by = c("food_grp", "dga_subgrp")) %>% 
  mutate(new_CF = grams_subgrp_tot / fpe_dy_2500)

whole_frt3 %>% View()

# Do fruit juice next to double check

# VEGETABLES (NON-STARCHY) -----

veg <- dat %>% filter(food_grp == "veg")

veg1 <- veg %>% mutate(prop_food_subgrp_new = prop_dga_subgrp*prop_food_subgrp)

sum(veg1$prop_food_subgrp_new) # should equal 1

veg_exc_sta_prop <- veg1 %>% filter(dga_subgrp_new == "veg_exc_sta") %>% select(prop_food_subgrp_new) %>% sum() 
# should equal 73.2%

rescale_num_veg <- 1/veg_exc_sta_prop

veg_exc_sta <- veg1 %>% 
  filter(dga_subgrp_new == "veg_exc_sta") %>% 
  mutate(new_prop = prop_food_subgrp_new * rescale_num_veg)

# proportion for veg should =1
veg_exc_sta %>% select(new_prop) %>% sum() #woo!

veg_exc_sta1 <- veg_exc_sta %>% select(FNDDS_food_code, food_item_cluster, food_grp, dga_subgrp_new,
                       FPED, FPED_CF, fpe_dy_2500, new_prop)

#Create diets with foods on 100g basis
veg_exc_sta2 <- veg_exc_sta1 %>% 
  mutate(ddiet_fpe_2500 = fpe_dy_2500*new_prop, #creating var for daily 2500 kcal pattern by food in fpe amounts
         ddiet_2500 = ddiet_fpe_2500*FPED_CF, #creating var for daily patterns by food in 100g amounts
         ddiet_2500_grams = ddiet_2500*100) %>% #Create gram amounts for bottom up g recommendations
  select(-fpe_dy_2500) #removing scaling vector 

#Add new column for food group proportions on a mass basis
veg_exc_sta3 <- 
  veg_exc_sta2 %>% 
  #group_by(food_grp) %>% 
  mutate(grams_grp_tot = sum(ddiet_2500_grams), #making new column with grp gram totals
         grams_subgrp_tot = sum(ddiet_2500_grams)) #making new column with subgrp gram totals

veg_exc_sta4 <- veg_exc_sta3 %>% 
  select(food_grp, dga_subgrp_new, grams_subgrp_tot) %>% 
  distinct() %>% 
  left_join(pattern_2500_dy_us, by = c("dga_subgrp_new" = "dga_subgrp", "food_grp")) %>% 
  mutate(new_CF = grams_subgrp_tot / fpe_dy_2500)

veg_exc_sta4 %>% View()


# merge fruit and veg
rbind(whole_frt3, veg_exc_sta4)









# export 

write_csv(whole_frt3, "in/Unit conversion/Blackstone 2020/new/whole_fruit_new_CF.csv")

