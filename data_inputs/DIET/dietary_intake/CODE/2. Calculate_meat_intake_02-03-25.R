# Deal with organ meat
# Brooke Bell
# 2-3-25

rm(list = ls())

library(tidyverse)
library(haven)

# read in meat data
meat_day1 <- read_sas("in/ALL PILLARS/Dietary intake/processed meat/out/meat_day1.sas7bdat")
meat_day2 <- read_sas("in/ALL PILLARS/Dietary intake/processed meat/out/meat_day2.sas7bdat")

# read in organ mapping
new_organ <- read_csv("in/ALL PILLARS/Dietary intake/processed meat/organ_meats_bothdays_mapped_121323.csv")

# DAY 1 -----

meat_day1_1 <- meat_day1 %>% filter(!(is.na(SEQN))) %>% select(SEQN, DESCRIPTION, FOODCODE, DR1ILINE, DR1IGRMS,
                                                               DR1I_PF_ORGAN,
                                                               # cured_redmeat, cured_poultry, Nug_Pat_Fil, unproc_poultry, 
                                                               total_redmeat, total_poultry
                                                               # , 
                                                               # total_proc_poultry, Red_and_cured_1, Red_and_processed_2
                                                               ) %>% 
  arrange(SEQN, DR1ILINE)

meat_day1_1 %>% filter(DR1I_PF_ORGAN > 0) %>% View()

# join with day1
meat_day1_2 <- left_join(meat_day1_1, new_organ, by = "DESCRIPTION")

meat_day1_3 <- meat_day1_2 %>% 
  rowwise() %>% 
  mutate(new = ifelse(is.na(new), "No change", new),
         total_redmeat_new = ifelse(new == "pf_redm", total_redmeat + DR1I_PF_ORGAN, total_redmeat),
         total_poultry_new = ifelse(new == "pf_poultry", total_poultry + DR1I_PF_ORGAN, total_poultry)) %>% 
  select(SEQN, DR1ILINE, total_redmeat_new, total_poultry_new)

# export
write_rds(meat_day1_3, "in/ALL PILLARS/Dietary intake/clean data/meat_day1.rds")

# DAY 2 -----

meat_day2_1 <- meat_day2 %>% filter(!(is.na(SEQN))) %>% select(SEQN, DESCRIPTION2, FOODCODE2, DR2ILINE, DR2IGRMS,
                                                               DR2I_PF_ORGAN, total_redmeat_day2, total_poultry_day2) %>% 
  arrange(SEQN, DR2ILINE)

meat_day2_1 %>% filter(DR2I_PF_ORGAN > 0) %>% View()

# join with day2
meat_day2_2 <- left_join(meat_day2_1, new_organ, by = c("DESCRIPTION2" = "DESCRIPTION"))

meat_day2_3 <- meat_day2_2 %>% 
  rowwise() %>% 
  mutate(new = ifelse(is.na(new), "No change", new),
         total_redmeat_new = ifelse(new == "pf_redm", total_redmeat_day2 + DR2I_PF_ORGAN, total_redmeat_day2),
         total_poultry_new = ifelse(new == "pf_poultry", total_poultry_day2 + DR2I_PF_ORGAN, total_poultry_day2)) %>% 
  select(SEQN, DR2ILINE, total_redmeat_new, total_poultry_new)

# export
write_rds(meat_day2_3, "in/ALL PILLARS/Dietary intake/clean data/meat_day2.rds")

