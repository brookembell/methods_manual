# Clean mean intake and SDs from cluster
# Brooke Bell
# 3-10-25

rm(list=ls())

library(tidyverse)

# Load necessary libraries
library(readr)
library(dplyr)

my_date <- Sys.Date()

# Specify the directory containing the CSV files
directory <- "outputs/intake/output_031025_ncimethod"

# Get the list of all CSV files in the directory
file_list <- list.files(path = directory, pattern = "*.csv", full.names = TRUE)

# Read each CSV file and store them in a list of data frames
data_list <- lapply(file_list, read_csv)

# Optionally, combine all data frames into one data frame
combined_data <- bind_rows(data_list)

intake <- combined_data %>% 
  select(note, subgroup_new, N, mean, mean_SE, StdDev) %>% 
  filter(subgroup_new %in% c(1:48)) %>% 
  rename(food = note, 
         subgroup = subgroup_new,
         SE = mean_SE) %>% 
  arrange(subgroup, food)

# fix food name
intake1 <- intake %>% 
  mutate(food = str_remove(food, "_adj$"))

# fix poultry
intake2 <- intake1 %>% 
  mutate(food = ifelse(food == "poult_tot", "pf_poultry_tot", food))

# merge with food labels
labels <- read_csv("data_inputs/OTHER/labels/DATA/dietary_factors_010424_FINAL.csv")

labels1 <- labels %>% 
  rename(food = Food_group) %>% 
  relocate(food)

# this is so lazy...i'm sorry
# read in pro_gro from original output
ratio <- read_csv("data_inputs/DIET/dietary_intake/DATA/output_data/NHANES_1518_summary_allfoods_adj_bysub_bysource_02-03-2025.csv") %>% 
  select(subgroup, food, pro_gro) %>% 
  mutate(subgroup = as.character(subgroup))

# join
intake3 <- left_join(intake2, labels1, by = "food") %>% 
  left_join(ratio, by = c("subgroup", "food"))

intake4 <- intake3 %>% 
  relocate(subgroup) %>% 
  rename(food_label = Var_label,
         food_desc = Var_desc) %>% 
  arrange(subgroup, food)

# export
write_csv(intake4, 
          paste0("data_inputs/DIET/dietary_intake/DATA/output_data_from_cluster/NHANES_1518_summary_allfoods_adj_bysub_ncimethod_", my_date, ".csv"))

