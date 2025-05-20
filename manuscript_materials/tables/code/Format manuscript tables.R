# Create manuscript tables
# Updated: 4-23-25

##### MUST OPEN 'METHODS_MANUAL' R PROJECT FIRST BEFORE RUNNING #####

rm(list = ls())

library(tidyverse)
library(kableExtra)
library(webshot2)
library(magick)

patterns <- c("US", "Veg", "Med", "Vegan", "DGAplus")

# TABLE 1 -----

# i <- "US"

# empty list
tab1_list <- list()

# for loop
for (i in patterns) {
  
  my_path <- paste0("outputs/model/output_032025_1000sims/CRA/", i, "/joint/summarystats_joint_attributable_USmortality_by_pathway_disease_type_2015_", i, ".csv")
  
  x <- read_csv(my_path) %>% 
    select(pathway, disease_type, medians, LB, UB) %>% 
    mutate(diet_pattern = paste0(i)) %>% 
    relocate(diet_pattern, disease_type) %>% 
    arrange(disease_type, pathway) 
  
  tab1_list[[i]] <- x

}

# combine into dataset
tab1_dat <- bind_rows(tab1_list)

# apply ceiling function to all values
tab1_dat1 <- tab1_dat %>% 
  mutate(across(c(medians, LB, UB), ceiling)) %>% 
  mutate(disease_type = recode(disease_type,
                               "CVD" = "CMD"),
         pathway = recode(pathway,
                          "direct" = "Direct",
                          "medBMI" = "BMI-mediated",
                          "medSBP" = "SBP-mediated"),
         diet_pattern = recode(diet_pattern,
                               "US" = "HUS",
                               "Med" = "MED",
                               "Veg" = "VEG",
                               "Vegan" = "PLNT",
                               "DGAplus" = "CDP")) %>% 
  arrange(diet_pattern, disease_type)

# long to wide
tab1_dat_wide <- pivot_wider(tab1_dat1,
                             id_cols = c(disease_type, pathway),
                             names_from = diet_pattern,
                             values_from = medians:UB)

# rearrange vars
tab1_dat_wide1 <- tab1_dat_wide %>% 
  relocate(
           medians_CDP,
           LB_CDP,
           UB_CDP,
    
           medians_HUS,
           LB_HUS,
           UB_HUS,
           
           medians_MED,
           LB_MED,
           UB_MED,
           
           medians_PLNT,
           LB_PLNT,
           UB_PLNT,
          
           medians_VEG,
           LB_VEG,
           UB_VEG,
           
           .after = pathway)

# export
write_csv(tab1_dat_wide1, "manuscript_materials/tables/formatted_tables/Table 1.csv")

# html table
tab1 <- tab1_dat_wide1 %>% 
  select(pathway, 
         starts_with("medians")) %>% 
  kable(booktabs = TRUE,
        format.args = list(big.mark = ","),
        align = c("r"),
        col.names = c("Pathway", "CDP", "HUS", "MED", "PLNT", "VEG")) %>%
  row_spec(row = 0, bold = TRUE) %>% 
  kable_classic("striped", full_width = F, html_font = "Cambria") %>% 
  # add_header_above(c(" " = 1, "Median (95% UI)" = 5)) %>% 
  pack_rows("CMD", 1, 3) %>% 
  pack_rows("Cancer", 4, 6) %>% 
  footnote(general = "Median (95% UI)")

save_kable(x = tab1, file = "manuscript_materials/tables/formatted_tables/table1.html", self_contained = T)
save_kable(x = tab1, file = "manuscript_materials/tables/formatted_tables/table1.pdf", density = 400)

# TABLE 2 (per capita) -----

rm(list = ls())

patterns <- c("US", "Veg", "Med", "Vegan", "DGAplus")

# test
# k <- "US"

# empty list
tab2_list <- list()

# for loop
for (k in patterns) {
  
  my_path <- paste0("outputs/model/output_032025_1000sims/cost_env/", k, "_diet_both/per_capita/By_SubGroup/summary.output_by_all.costenv.csv")
  
  z <- read_csv(my_path) %>% 
    select(outcome, outcome_unit, 
           impact_median, `impact_lower_bound (2.5th percentile)`, `impact_upper_bound (97.5th percentile)`,
           combined_consumed_impact_median, `combined_consumed_impact_lower_bound (2.5th percentile)`, `combined_consumed_upper_bound (97.5th percentile)`,
           combined_unconsumed_impact_median, `combined_unconsumed_impact_lower_bound (2.5th percentile)`, `combined_unconsumed_upper_bound (97.5th percentile)`,
           inedible_impact_median, `inedible_impact_lower_bound (2.5th percentile)`, `inedible_upper_bound (97.5th percentile)`,
           wasted_impact_median, `wasted_impact_lower_bound (2.5th percentile)`, `wasted_unconsumed_upper_bound (97.5th percentile)`,
    ) %>% 
    rename(total_impact_median = impact_median,
           total_impact_LB = `impact_lower_bound (2.5th percentile)`,
           total_impact_UB = `impact_upper_bound (97.5th percentile)`,
           consumed_impact_median = combined_consumed_impact_median,
           consumed_impact_LB = `combined_consumed_impact_lower_bound (2.5th percentile)`,
           consumed_impact_UB = `combined_consumed_upper_bound (97.5th percentile)`,
           unconsumed_impact_median = combined_unconsumed_impact_median,
           unconsumed_impact_LB = `combined_unconsumed_impact_lower_bound (2.5th percentile)`,
           unconsumed_impact_UB = `combined_unconsumed_upper_bound (97.5th percentile)`,
           inedible_impact_LB = `inedible_impact_lower_bound (2.5th percentile)`,
           inedible_impact_UB = `inedible_upper_bound (97.5th percentile)`,
           wasted_impact_LB = `wasted_impact_lower_bound (2.5th percentile)`,
           wasted_impact_UB = `wasted_unconsumed_upper_bound (97.5th percentile)`) %>% 
    mutate(diet_pattern = paste0(k)) %>% 
    relocate(diet_pattern) %>% 
    arrange(outcome) 
  
  tab2_list[[k]] <- z
  
}

# combine into dataset
tab2_dat <- bind_rows(tab2_list)

# apply ceiling function to all values
tab2_dat1 <- tab2_dat %>% 
  mutate(across(total_impact_median:wasted_impact_UB, ~ round(.x * 365, digits = 0)),
         diet_pattern = recode(diet_pattern,
                               "US" = "HUS",
                               "Med" = "MED",
                               "Veg" = "VEG",
                               "Vegan" = "PLNT",
                               "DGAplus" = "CDP"))

# long to wide
tab2_dat_wide <- pivot_wider(tab2_dat1,
                             id_cols = c(outcome, outcome_unit),
                             names_from = diet_pattern,
                             values_from = total_impact_median:wasted_impact_UB) %>% 
  mutate(pillar = case_match(outcome,
                             "GHG" ~ "Environment",
                             "BLUEWATER" ~ "Environment",
                             "CED" ~ "Environment",
                             "WATER" ~ "Environment",
                             "Food_price" ~ "Economic",
                             "FL" ~ "Social")) %>% 
  relocate(pillar) %>% 
  arrange(pillar, outcome)

# rearrange vars
tab2_dat_wide1 <- tab2_dat_wide %>% 
  relocate(total_impact_median_CDP,
           total_impact_LB_CDP,
           total_impact_UB_CDP,
           
           total_impact_median_HUS,
           total_impact_LB_HUS,
           total_impact_UB_HUS,
           
           total_impact_median_MED,
           total_impact_LB_MED,
           total_impact_UB_MED,
           
           total_impact_median_PLNT,
           total_impact_LB_PLNT,
           total_impact_UB_PLNT,
           
           total_impact_median_VEG,
           total_impact_LB_VEG,
           total_impact_UB_VEG,
           
           consumed_impact_median_CDP,
           consumed_impact_LB_CDP,
           consumed_impact_UB_CDP,
           
           consumed_impact_median_HUS,
           consumed_impact_LB_HUS,
           consumed_impact_UB_HUS,
           
           consumed_impact_median_MED,
           consumed_impact_LB_MED,
           consumed_impact_UB_MED,
           
           consumed_impact_median_PLNT,
           consumed_impact_LB_PLNT,
           consumed_impact_UB_PLNT,
           
           consumed_impact_median_VEG,
           consumed_impact_LB_VEG,
           consumed_impact_UB_VEG,
           
           inedible_impact_median_CDP,
           inedible_impact_LB_CDP,
           inedible_impact_UB_CDP,

           inedible_impact_median_HUS,
           inedible_impact_LB_HUS,
           inedible_impact_UB_HUS,
           
           inedible_impact_median_MED,
           inedible_impact_LB_MED,
           inedible_impact_UB_MED,
           
           inedible_impact_median_PLNT,
           inedible_impact_LB_PLNT,
           inedible_impact_UB_PLNT,
           
           inedible_impact_median_VEG,
           inedible_impact_LB_VEG,
           inedible_impact_UB_VEG,
           
           wasted_impact_median_CDP,
           wasted_impact_LB_CDP,
           wasted_impact_UB_CDP,
          
           wasted_impact_median_HUS,
           wasted_impact_LB_HUS,
           wasted_impact_UB_HUS,
           
           wasted_impact_median_MED,
           wasted_impact_LB_MED,
           wasted_impact_UB_MED,
           
           wasted_impact_median_PLNT,
           wasted_impact_LB_PLNT,
           wasted_impact_UB_PLNT,
           
           wasted_impact_median_VEG,
           wasted_impact_LB_VEG,
           wasted_impact_UB_VEG,

           .after = outcome_unit)

# export
write_csv(tab2_dat_wide1, "manuscript_materials/tables/formatted_tables/Table 2 (annual per capita).csv")

# html table 2a (total)
tab2a <- tab2_dat_wide1 %>% 
  select(outcome, outcome_unit, 
         starts_with("total_impact_median")) %>% 
  mutate(outcome = recode(outcome,
                          "BLUEWATER" = "Bluewater use",
                          "CED" = "Cumulative energy demand",
                          "GHG" = "Greenhouse gas emissions",
                          "WATER" = "Water scarcity",
                          "FL" = "Risk of forced labor",
                          "Food_price" = "Food price")) %>% 
  kable(booktabs = TRUE,
        format.args = list(big.mark = ","),
        align = c("r"),
        col.names = c("Outcome", "Unit", "CDP", "HUS", "MED", "PLNT", "VEG")) %>%
  row_spec(row = 0, bold = TRUE) %>% 
  kable_classic("striped", full_width = F, html_font = "Cambria") %>% 
  add_header_above(c(" " = 2, "Total" = 5), bold = TRUE) %>% 
  pack_rows("Economic", 1, 1) %>% 
  pack_rows("Environment", 2, 5) %>% 
  pack_rows("Social", 6, 6) %>% 
  footnote(general = "Median (95% UI)") 

# save as html and png
save_kable(x = tab2a, file = "manuscript_materials/tables/formatted_tables/table2a.html", self_contained = T)
save_kable(x = tab2a, file = "manuscript_materials/tables/formatted_tables/table2a.pdf", density = 400)

# html table 2b (consumed, inedible, wasted)
tab2b <- tab2_dat_wide1 %>% 
  select(outcome, outcome_unit, 
         starts_with("consumed_impact_median"), 
         starts_with("inedible_impact_median"),
         starts_with("wasted_impact_median")) %>% 
  mutate(outcome = recode(outcome,
                          "BLUEWATER" = "Bluewater use",
                          "CED" = "Cumulative energy demand",
                          "GHG" = "Greenhouse gas emissions",
                          "WATER" = "Water scarcity",
                          "FL" = "Risk of forced labor",
                          "Food_price" = "Food price")) %>% 
  kable(booktabs = TRUE,
        format.args = list(big.mark = ","),
        align = c("r"),
        col.names = c("Outcome", "Unit", "CDP", "HUS", "MED", "PLNT", "VEG", "CDP", "HUS", "MED", "PLNT", "VEG", "CDP", "HUS", "MED", "PLNT", "VEG")) %>%
  row_spec(row = 0, bold = TRUE) %>% 
  kable_classic("striped", full_width = F, html_font = "Cambria") %>% 
  add_header_above(c(" " = 2, "Consumed" = 5, "Inedible" = 5, "Wasted" = 5), bold = TRUE) %>% 
  pack_rows("Economic", 1, 1) %>% 
  pack_rows("Environment", 2, 5) %>% 
  pack_rows("Social", 6, 6) %>%   
  footnote(general = "Median (95% UI)")

# save as html and png
save_kable(x = tab2b, file = "manuscript_materials/tables/formatted_tables/table2b.html", self_contained = T)
save_kable(x = tab2b, file = "manuscript_materials/tables/formatted_tables/table2b.pdf", density = 400)

# TABLE 3 (absolute - 10% shift) -----

rm(list = ls())

patterns <- c("US", "Veg", "Med", "Vegan", "DGAplus")

# test
# j <- "US"

# empty list
tab3_list <- list()

# for loop
for (j in patterns) {
  
  new_path <- paste0("outputs/model/output_032025_1000sims/cost_env/", j, "_diet_both/By_SubGroup/summary.output_by_all.costenv.csv")
  
  y <- read_csv(new_path) %>% 
    select(outcome, outcome_unit, 
           impact_median, `impact_lower_bound (2.5th percentile)`, `impact_upper_bound (97.5th percentile)`
           # ,
           # combined_consumed_impact_median, `combined_consumed_impact_lower_bound (2.5th percentile)`, `combined_consumed_upper_bound (97.5th percentile)`,
           # combined_unconsumed_impact_median, `combined_unconsumed_impact_lower_bound (2.5th percentile)`, `combined_unconsumed_upper_bound (97.5th percentile)`,
           # inedible_impact_median, `inedible_impact_lower_bound (2.5th percentile)`, `inedible_upper_bound (97.5th percentile)`,
           # wasted_impact_median, `wasted_impact_lower_bound (2.5th percentile)`, `wasted_unconsumed_upper_bound (97.5th percentile)`
           ) %>% 
    rename(total_impact_median = impact_median,
           total_impact_LB = `impact_lower_bound (2.5th percentile)`,
           total_impact_UB = `impact_upper_bound (97.5th percentile)`
           # ,
           # consumed_impact_median = combined_consumed_impact_median,
           # consumed_impact_LB = `combined_consumed_impact_lower_bound (2.5th percentile)`,
           # consumed_impact_UB = `combined_consumed_upper_bound (97.5th percentile)`,
           # unconsumed_impact_median = combined_unconsumed_impact_median,
           # unconsumed_impact_LB = `combined_unconsumed_impact_lower_bound (2.5th percentile)`,
           # unconsumed_impact_UB = `combined_unconsumed_upper_bound (97.5th percentile)`,
           # inedible_impact_LB = `inedible_impact_lower_bound (2.5th percentile)`,
           # inedible_impact_UB = `inedible_upper_bound (97.5th percentile)`,
           # wasted_impact_LB = `wasted_impact_lower_bound (2.5th percentile)`,
           # wasted_impact_UB = `wasted_unconsumed_upper_bound (97.5th percentile)`
           ) %>% 
    mutate(diet_pattern = paste0(j)) %>% 
    relocate(diet_pattern) %>% 
    arrange(outcome) 
  
  tab3_list[[j]] <- y
  
}

# combine into dataset
tab3_dat <- bind_rows(tab3_list)

# apply ceiling function to all values
# calcuate 1/10th impact
tab3_dat1 <- tab3_dat %>% 
  mutate(across(total_impact_median:total_impact_UB, ~ (.x * 365) / 10),
         diet_pattern = recode(diet_pattern,
                               "US" = "HUS",
                               "Med" = "MED",
                               "Veg" = "VEG",
                               "Vegan" = "PLNT",
                               "DGAplus" = "CDP")) %>% 
  arrange(diet_pattern, outcome)

# transform units?
foo <- tab3_dat1 %>% 
  mutate(impact_new = case_when(
    outcome == "BLUEWATER" ~ round(total_impact_median / 1000000000, digits = 2), #billion
    outcome == "WATER" ~ round(total_impact_median / 1000000000, digits = 2), #billion
    outcome == "Food_price" ~ round(total_impact_median / 1000000, digits = 2), #million
    outcome == "FL" ~ round(total_impact_median / 100000, digits = 2), #hundred thousand
    outcome == "CED" ~ round(total_impact_median / 1000000, digits = 2), #million
    outcome == "GHG" ~ round(total_impact_median / 1000000, digits = 2)), #million
    
    LB_new = case_when(
      outcome == "BLUEWATER" ~ round(total_impact_LB / 1000000000, digits = 2), #billion
      outcome == "WATER" ~ round(total_impact_LB / 1000000000, digits = 2), #billion
      outcome == "Food_price" ~ round(total_impact_LB / 1000000, digits = 2), #million
      outcome == "FL" ~ round(total_impact_LB / 100000, digits = 2), #hundred thousand
      outcome == "CED" ~ round(total_impact_LB / 1000000, digits = 2), #million
      outcome == "GHG" ~ round(total_impact_LB / 1000000, digits = 2)), #million 
    
    UB_new = case_when(
      outcome == "BLUEWATER" ~ round(total_impact_UB / 1000000000, digits = 2), #billion
      outcome == "WATER" ~ round(total_impact_UB / 1000000000, digits = 2), #billion
      outcome == "Food_price" ~ round(total_impact_UB / 1000000, digits = 2), #million
      outcome == "FL" ~ round(total_impact_UB / 100000, digits = 2), #hundred thousand
      outcome == "CED" ~ round(total_impact_UB / 1000000, digits = 2), #million
      outcome == "GHG" ~ round(total_impact_UB / 1000000, digits = 2)), #million 
    
    unit_new = case_when(
      outcome == "BLUEWATER" ~ paste0("billion ", outcome_unit), #billion
      outcome == "WATER" ~ paste0("billion ", outcome_unit), #billion
      outcome == "Food_price" ~ paste0("million ", outcome_unit), #million
      outcome == "FL" ~ paste0("hundred thousand ", outcome_unit), #hundred thousand
      outcome == "CED" ~ paste0("million ", outcome_unit), #million
      outcome == "GHG" ~ paste0("million ", outcome_unit) #million 
    )) %>% 
  select(diet_pattern, outcome, unit_new, impact_new, LB_new, UB_new)

# long to wide
tab3_dat_wide <- pivot_wider(foo,
                             id_cols = c(outcome, unit_new),
                             names_from = diet_pattern,
                             values_from = impact_new:UB_new)

# rearrange vars
tab3_dat_wide1 <- tab3_dat_wide %>% 
  relocate(impact_new_CDP,
           LB_new_CDP,
           UB_new_CDP,
           
           impact_new_HUS,
           LB_new_HUS,
           UB_new_HUS,
           
           impact_new_MED,
           LB_new_MED,
           UB_new_MED,
           
           impact_new_PLNT,
           LB_new_PLNT,
           UB_new_PLNT,
           
           impact_new_VEG,
           LB_new_VEG,
           UB_new_VEG,
           
           .after = unit_new) %>% 
  mutate(outcome = recode(outcome,
                          "BLUEWATER" = "Bluewater use",
                          "CED" = "Cumulative energy demand",
                          "GHG" = "Greenhouse gas emissions",
                          "WATER" = "Water scarcity",
                          "FL" = "Risk of forced labor",
                          "Food_price" = "Food price")) %>% 
  arrange(outcome)


# export
write_csv(tab3_dat_wide1, "manuscript_materials/tables/formatted_tables/Table 3 (10% shift)_new.csv")

# html table
tab3 <- tab3_dat_wide1 %>% 
  select(outcome, unit_new, starts_with("impact_new_")) %>% 
  kable(booktabs = TRUE,
        format.args = list(big.mark = ","),
        align = c("r"),
        col.names = c("Outcome", "Unit", "CDP", "HUS", "MED", "PLNT", "VEG")) %>%
  row_spec(row = 0, bold = TRUE) %>% 
  kable_classic("striped", full_width = F, html_font = "Cambria") %>% 
  # add_header_above(c(" " = 1, "Median (95% UI)" = 5)) %>% 
  # pack_rows("CMD", 1, 3) %>% 
  # pack_rows("Cancer", 4, 6) %>% 
  footnote(general = "Median (95% UI)")

save_kable(x = tab3, file = "manuscript_materials/tables/formatted_tables/table3_new.html", self_contained = T)
save_kable(x = tab3, file = "manuscript_materials/tables/formatted_tables/table3.pdf", density = 400)



