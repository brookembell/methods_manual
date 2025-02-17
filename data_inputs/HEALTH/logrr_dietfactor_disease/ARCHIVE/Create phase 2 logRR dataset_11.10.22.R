# Create Phase 2 dataset: logRRs for diet and disease outcomes

rm(list = ls())
library(tidyverse)

setwd("/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/model development")


# Retrieve list of disease outcomes
disease_dat <- readxl::read_xlsx("Disease outcome labels 10.14.22.xlsx")
disease_outcomes <- c(disease_dat$outcome)
disease_labels <- c(disease_dat$outcome_label)

# Retrieve list of dietary factors
diet_dat <- readxl::read_xlsx("Dietary_factors_9.26.22.xlsx")
diet_factors <- c(diet_dat$Food_group)

# Retrieve population subgroups
pop_dat <- readxl::read_xlsx("Population_subgroups_48_9.26.xlsx")

# Number of population subgroups
subgroup_num <- 1:48

my_list <- list()

for (i in diet_factors) {
  
  dat <- tibble(
    #subgroup=1, 
    outcome=disease_outcomes, 
    outcome_label=disease_labels,
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
final_dat1 <- final_dat %>% left_join(pop_dat, by = "subgroup")

# JOIN WITH CVD AND CANCER DATASETS

# Retrieve cvd dataset
cvd_real <- 
  read_csv("data_new/in/Log RRs for diet and disease/logRR_diet_cvd_11.9.22.csv") %>% 
  select(-outcome_label)

# Retrieve cancer dataset
cancer_real <- 
  read_csv("data_new/in/Log RRs for diet and disease/logRR_diet_cancer_11.9.22.csv") %>% 
  select(-outcome_label) %>% 
  mutate(Age=NA,
         Age_label=NA)

final_dat2 <- rbind(cvd_real, cancer_real)

# join
# final_dat_cancer <- left_join(final_dat1, cancer_real, by = c("outcome", "risk_factor"))
# final_dat_cvd <- left_join(final_dat1, cvd_real, by = c("outcome", "risk_factor", "Age", "Age_label"))

write.csv(final_dat2, 
          "data_new/in/Log RRs for diet and disease/logRR_diet_disease_11.10.22.csv",
          row.names = FALSE)

