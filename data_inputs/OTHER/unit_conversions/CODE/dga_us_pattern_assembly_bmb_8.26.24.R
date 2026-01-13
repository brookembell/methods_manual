# This code is used to re-estimate the conversion factors (grams to servings) 
# for fruit (excl. juice) and vegetables (excl. starchy)
# Author: Brooke Bell

# Set up 

rm(list = ls())

library(tidyverse)

# Import data

pattern_2500_dy_us <- 
  read.csv("in/Unit conversion/Blackstone 2020/new/pattern_2500_dy_us_new_9.4.23.csv") %>% 
  filter(food_grp %in% c("veg", "fruit", "protein"))

fped_crosswalk_eat <- 
  read.csv("in/Unit conversion/Blackstone 2020/new/fped_crosswalk_eat_new_9.4.23.csv") %>% 
  select(-X) %>% 
  filter(food_grp %in% c("veg", "fruit") | dga_subgrp_new  == "leg_tot")

dat <- left_join(fped_crosswalk_eat, pattern_2500_dy_us, 
                 by = c("dga_subgrp_new", "food_grp")) %>% 
  rows_patch(pattern_2500_dy_us %>% 
               filter(food_grp == "protein") %>% 
               select(-food_grp) %>% 
               rename(dga_subgrp = dga_subgrp_new)
             )

# JUST FOCUS ON FRUIT FIRST -----

frt <- dat %>% filter(food_grp == "fruit")

# rescale the proportion variable s.t. it sums to 1 for whole_fruit
# 
# whole_frt_prop <- frt %>% filter(dga_subgrp_new == "whole_fruit") %>% select(prop_dga_subgrp) %>% sum()
# fruit_juice_prop <- frt %>% filter(dga_subgrp_new == "fruit_juice") %>% select(prop_dga_subgrp) %>% sum()
# 
# rescale_whole_frt <- 1/whole_frt_prop
# rescale_frt_juice <- 1/fruit_juice_prop

frt1 <- frt %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(rescale_num = 1/sum(prop_dga_subgrp),
         new_prop = prop_dga_subgrp * rescale_num) %>% 
  ungroup()

# whole_frt <- frt %>% 
#   filter(dga_subgrp == "whole_fruit") %>% 
#   mutate(new_prop = prop_dga_subgrp * rescale_num)

# proportion for fruit should =1
# whole_frt %>% select(new_prop) %>% sum() #woo!
frt1 %>% filter(dga_subgrp_new == "whole_fruit") %>% select(new_prop) %>% sum()
frt1 %>% filter(dga_subgrp_new == "fruit_juice") %>% select(new_prop) %>% sum()

#Create diets with foods on 100g basis
frt2 <- 
  frt1 %>% 
  mutate(ddiet_fpe_2500 = fpe_dy_2500*new_prop, #creating var for daily 2500 kcal pattern by food in fpe amounts
         ddiet_2500 = ddiet_fpe_2500*FPED_CF, #creating var for daily patterns by food in 100g amounts
         ddiet_2500_grams = ddiet_2500*100) %>% #Create gram amounts for bottom up g recommendations
  select(-fpe_dy_2500) #removing scaling vector 

#Add new column for food group proportions on a mass basis
frt3 <- 
  frt2 %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(
    #grams_grp_tot = sum(ddiet_2500_grams), #making new column with grp gram totals
         grams_subgrp_tot = sum(ddiet_2500_grams)) #making new column with subgrp gram totals

frt4 <- 
  frt3 %>% 
  select(food_grp, dga_subgrp_new, grams_subgrp_tot) %>% 
  distinct() %>% 
  left_join(pattern_2500_dy_us, by = c("food_grp", "dga_subgrp_new")) %>% 
  mutate(new_CF = grams_subgrp_tot / fpe_dy_2500)

frt4 %>% View()

# VEGETABLES (NON-STARCHY) -----

veg <- dat %>% filter(food_grp == "veg")

# rescale the proportion variable s.t. it sums to 1 for whole_fruit
# 
# whole_frt_prop <- frt %>% filter(dga_subgrp_new == "whole_fruit") %>% select(prop_dga_subgrp) %>% sum()
# fruit_juice_prop <- frt %>% filter(dga_subgrp_new == "fruit_juice") %>% select(prop_dga_subgrp) %>% sum()
# 
# rescale_whole_frt <- 1/whole_frt_prop
# rescale_frt_juice <- 1/fruit_juice_prop

veg1 <- 
  veg %>% 
  mutate(prop_dga_subgrp_updated = prop_dga_subgrp*prop_food_subgrp)

#should add to 1
sum(veg1$prop_dga_subgrp_updated) #good

veg2 <- 
  veg1 %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(rescale_num = 1/sum(prop_dga_subgrp_updated),
         new_prop = prop_dga_subgrp_updated * rescale_num) %>% 
  ungroup()

# whole_frt <- frt %>% 
#   filter(dga_subgrp == "whole_fruit") %>% 
#   mutate(new_prop = prop_dga_subgrp * rescale_num)

# proportion for fruit should =1
# whole_frt %>% select(new_prop) %>% sum() #woo!
veg2 %>% filter(dga_subgrp_new == "veg_exc_sta") %>% select(new_prop) %>% sum()
veg2 %>% filter(dga_subgrp_new == "veg_sta") %>% select(new_prop) %>% sum()

#Create diets with foods on 100g basis
veg3 <- 
  veg2 %>% 
  mutate(ddiet_fpe_2500 = fpe_dy_2500*new_prop, #creating var for daily 2500 kcal pattern by food in fpe amounts
         ddiet_2500 = ddiet_fpe_2500*FPED_CF, #creating var for daily patterns by food in 100g amounts
         ddiet_2500_grams = ddiet_2500*100) %>% #Create gram amounts for bottom up g recommendations
  select(-fpe_dy_2500) #removing scaling vector 

#Add new column for food group proportions on a mass basis
veg4 <- 
  veg3 %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(
    #grams_grp_tot = sum(ddiet_2500_grams), #making new column with grp gram totals
    grams_subgrp_tot = sum(ddiet_2500_grams)) #making new column with subgrp gram totals

veg5 <- 
  veg4 %>% 
  select(food_grp, dga_subgrp_new, grams_subgrp_tot) %>% 
  distinct() %>% 
  left_join(pattern_2500_dy_us, by = c("food_grp", "dga_subgrp_new")) %>% 
  mutate(new_CF = grams_subgrp_tot / fpe_dy_2500)

veg5 %>% View()

# LEGUMES -----

leg <- dat %>% filter(food_grp == "protein")

leg1 <- 
  leg %>% 
  mutate(prop_dga_subgrp_updated = prop_dga_subgrp*prop_food_subgrp)

#should add to 1
sum(leg1$prop_dga_subgrp_updated) #good

leg2 <- 
  leg1 %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(rescale_num = 1/sum(prop_dga_subgrp_updated),
         new_prop = prop_dga_subgrp_updated * rescale_num) %>% 
  ungroup()

# proportion should =1
leg2 %>% filter(dga_subgrp_new == "leg_tot") %>% select(new_prop) %>% sum()

#Create diets with foods on 100g basis
leg3 <- 
  leg2 %>% 
  mutate(ddiet_fpe_2500 = fpe_dy_2500*new_prop, #creating var for daily 2500 kcal pattern by food in fpe amounts
         ddiet_2500 = ddiet_fpe_2500*FPED_CF, #creating var for daily patterns by food in 100g amounts
         ddiet_2500_grams = ddiet_2500*100) %>% #Create gram amounts for bottom up g recommendations
  select(-fpe_dy_2500) #removing scaling vector 

#Add new column for food group proportions on a mass basis
leg4 <- 
  leg3 %>% 
  group_by(dga_subgrp_new) %>% 
  mutate(
    #grams_grp_tot = sum(ddiet_2500_grams), #making new column with grp gram totals
    grams_subgrp_tot = sum(ddiet_2500_grams)) #making new column with subgrp gram totals

leg5 <- 
  leg4 %>% 
  select(food_grp, dga_subgrp_new, grams_subgrp_tot) %>% 
  distinct() %>% 
  mutate(fpe_dy_2500 = 1.36, # 1.28oz (bean CF) + 0.08oz (soy CF) = 1.36oz
         new_CF = grams_subgrp_tot / fpe_dy_2500)

leg5 %>% View()

# merge fruit and veg
new_cfs <- rbind(frt4, veg5, leg5) %>% mutate(new_CF_rounded = round(new_CF))

# fix units for legumes
new_cfs1 <- new_cfs %>% mutate(unit = ifelse(dga_subgrp_new == "leg_tot", "oz/day", unit))

# export 

write_csv(new_cfs1, "in/Unit conversion/Blackstone 2020/new/new_CFs_090423.csv")



