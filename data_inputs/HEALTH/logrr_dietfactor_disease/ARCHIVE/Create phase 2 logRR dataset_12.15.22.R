# Create Phase 2 dataset: logRRs for diet and disease outcomes

rm(list = ls())
library(tidyverse)

#setwd("/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/model development")


# Retrieve list of disease outcomes
disease_dat <- readxl::read_xlsx("in/Disease outcome labels 10.14.22.xlsx")
disease_outcomes <- c(disease_dat$outcome)
disease_labels <- c(disease_dat$outcome_label)

# Retrieve list of dietary factors
diet_dat <- readxl::read_xlsx("in/Dietary_factors_9.26.22.xlsx")
diet_factors <- c(diet_dat$Food_group)

# Retrieve population subgroups
pop_dat <- readxl::read_xlsx("in/Population_subgroups_48_9.26.xlsx")

pop_dat1 <- pop_dat %>% select(subgroup, Age, Sex, Race)

# Number of population subgroups
subgroup_num <- 1:48

my_list <- list()

for (i in diet_factors) {
  
  dat <- tibble(
    #subgroup=1, 
    outcome=disease_outcomes, 
    #outcome_label=disease_labels,
    risk_factor=i)

my_list[[i]] <- dat
  
}

dat_bind <- bind_rows(my_list)

#second loop

my_list1 <- list()

for (j in subgroup_num) {
  
  dat_bind_more <- 
    dat_bind %>% 
    mutate(subgroup = j)
  
  my_list1[[j]] <- dat_bind_more
  
}

final_dat <- bind_rows(my_list1)

# Left join with pop dataset
final_dat1 <- final_dat %>% left_join(pop_dat1, by = "subgroup")

# JOIN WITH CVD AND CANCER DATASETS

# Retrieve cvd dataset
cvd_real <- 
  read_csv("in/Log RRs for diet and disease/logRR_diet_cvd_11.9.22.csv") %>% 
  select(-c(outcome_label, Age_label)) %>% 
  #udpate 12/15
  #need to change fruit name
  mutate(risk_factor = recode(risk_factor, 
                              "fruit" = "fruit_exc_juice"))

# join with final_dat1
join1 <- left_join(final_dat1, cvd_real, by = c("outcome", "risk_factor", "Age"))

# test
join1 %>% filter(outcome == "IHD" & risk_factor == "fruit_exc_juice") %>% View() #good

# Retrieve cancer dataset
cancer_real <- 
  read_csv("in/Log RRs for diet and disease/logRR_diet_cancer_11.9.22.csv") %>% 
  select(-outcome_label) %>% 
  #udpate 12/15
  #need to change fruit name
  mutate(risk_factor = recode(risk_factor, 
                              "fruit" = "fruit_exc_juice"))
  

# join with join1
join2 <- left_join(final_dat1, cancer_real, by = c("outcome", "risk_factor"))

# test
join2 %>% filter(outcome == "CC" & risk_factor == "dairy") %>% View() #good

# need to merge join1 and join2

# attempt 1 - get rid of rows where rr=na
join1_sub <- join1 %>% filter(!(is.na(RR)))
join2_sub <- join2 %>% filter(!(is.na(RR)))

# combine these datasets
my_join <- rbind(join1_sub, join2_sub)

# lastly, join with final_dat1 template
big_join <- left_join(final_dat1, my_join, by=NULL)

# fill in NA values
big_join1 <- big_join %>% mutate(RR = ifelse(is.na(RR), 1, RR),
                    CI_lower = ifelse(is.na(CI_lower), 1, CI_lower),
                    CI_upper = ifelse(is.na(CI_upper), 1, CI_upper),
                    logRR = ifelse(is.na(logRR), 0, logRR),
                    logCI_lower = ifelse(is.na(logCI_lower), 0, logCI_lower),
                    logCI_upper = ifelse(is.na(logCI_upper), 0, logCI_upper),
                    RR_unit = ifelse(is.na(RR_unit), "100 g/d", RR_unit))

# reorder columns
big_join2 <- big_join1 %>% 
  relocate(subgroup, Age, Sex, Race) %>% 
  arrange(subgroup, outcome)

write.csv(big_join2, 
          "in/Log RRs for diet and disease/logRR_diet_disease_12.15.22.csv",
          row.names = FALSE)

