
rm(list = ls())

library(tidyverse)

setwd("/Users/bmb73/Library/CloudStorage/Box-Box/lasting_aim_3/model development/data_new/in/CVD incidence/Brooke")

#2012 data
cvd12_wide <- read_csv("cvd2012_bmb.csv")

cvd12_wide1 <- cvd12_wide %>% rename(age = Age,
                                     gender = Sex,
                                     race = Race,
                                     DM = DIAB) %>% 
  select(age, gender, race, IHD, ISTK, HSTK, OSTK, DM, HHD, AA, RHD, ENDO, OTH, CM, AFF, PVD, TSTK)

#2018 data
cvd18 <- read_csv("cvd2018_bmb.csv")

cvd18_wide <- pivot_wider(cvd18, names_from = cause, values_from = Deaths)

cvd18_wide1 <- cvd18_wide %>% 
  arrange(race, gender, age) %>% 
  relocate(race, gender, age, IHD, ISTK, HSTK, OSTK, DM, AA, RHD, ENDO, OTH, CM, AFF, PVD, TSTK)

write_csv(cvd18_wide1, "cvd2018_wide_bmb.csv")

# update column names
colnames(cvd18_wide1)[c(4:17)] <- paste(colnames(cvd18_wide1)[c(4:17)], "2018", sep = "_")

#merge 2012 and 2018 datasets
cvd_join <- left_join(cvd12_wide1, cvd18_wide1, by = c("age", "gender", "race"))

# calculate %change: (2018-2012)/2012 * 100
cvd_join1 <- cvd_join %>% mutate(IHD_chg = ((IHD_2018 - IHD)/IHD) * 100,
                    ISTK_chg = ((ISTK_2018 - ISTK)/ISTK) * 100,
                    HSTK_chg = ((HSTK_2018 - HSTK)/HSTK) * 100,
                    OSTK_chg = ((OSTK_2018 - OSTK)/OSTK) * 100,
                    DM_chg = ((DM_2018 - DM)/DM) * 100,
                    AA_chg = ((AA_2018 - AA)/AA) * 100,
                    RHD_chg = ((RHD_2018 - RHD)/RHD) * 100,
                    ENDO_chg = ((ENDO_2018 - ENDO)/ENDO) * 100,
                    OTH_chg = ((OTH_2018 - OTH)/OTH) * 100,
                    CM_chg = ((CM_2018 - CM)/CM) * 100,
                    AFF_chg = ((AFF_2018 - AFF)/AFF) * 100,
                    PVD_chg = ((PVD_2018 - PVD)/PVD) * 100,
                    TSTK_chg = ((TSTK_2018 - TSTK)/TSTK) * 100)

# select values that are > 50%

cvd_join1 %>% select(age, gender, race, ends_with("_chg")) %>% View()

# look at each disease one at a time

# IHD
cvd_join1 %>% 
  select(age, gender, race, starts_with("IHD")) %>% 
  filter(IHD_chg > 14 | IHD_chg < -14) %>% 
  View() # looks fine

# ISTK
cvd_join1 %>% 
  select(age, gender, race, starts_with("ISTK")) %>% 
  filter(ISTK_chg > 14 | ISTK_chg < -14) %>% 
  View() # a lot of big changes

# HSTK
cvd_join1 %>% 
  select(age, gender, race, starts_with("HSTK")) %>% 
  filter(HSTK_chg > 14 | HSTK_chg < -14) %>% 
  View() # all consistently lower, which is an unexpected direction

# OSTK
cvd_join1 %>% 
  select(age, gender, race, starts_with("OSTK")) %>% 
  filter(OSTK_chg > 14 | OSTK_chg < -14) %>% 
  View() # looks fine

# DM
cvd_join1 %>% 
  select(age, gender, race, starts_with("DM")) %>% 
  filter(DM_chg > 14 | DM_chg < -14) %>% 
  View() # looks fine

# AA
cvd_join1 %>% 
  select(age, gender, race, starts_with("AA")) %>% 
  filter(AA_chg > 14 | AA_chg < -14) %>% 
  View() # looks fine

# RHD
cvd_join1 %>% 
  select(age, gender, race, starts_with("RHD")) %>% 
  filter(RHD_chg > 14 | RHD_chg < -14) %>% 
  View() # looks fine

# ENDO
cvd_join1 %>% 
  select(age, gender, race, starts_with("ENDO")) %>% 
  filter(ENDO_chg > 14 | ENDO_chg < -14) %>% 
  View() # looks fine

# OTH
cvd_join1 %>% 
  select(age, gender, race, starts_with("OTH")) %>% 
  filter(OTH_chg > 14 | OTH_chg < -14) %>% 
  View() # looks fine

# CM
cvd_join1 %>% 
  select(age, gender, race, starts_with("CM")) %>% 
  filter(CM_chg > 14 | CM_chg < -14) %>% 
  View() # very weird numbers...

# AFF
cvd_join1 %>% 
  select(age, gender, race, starts_with("AFF")) %>% 
  filter(AFF_chg > 14 | AFF_chg < -14) %>% 
  View() # looks fine

# PVD
cvd_join1 %>% 
  select(age, gender, race, starts_with("PVD")) %>% 
  filter(PVD_chg > 14 | PVD_chg < -14) %>% 
  View() # looks fine

# TSTK
cvd_join1 %>% 
  select(age, gender, race, starts_with("TSTK")) %>% 
  filter(TSTK_chg > 14 | TSTK_chg < -14) %>% 
  View() # looks fine

# Summary: most numbers looks fine, ISTK and HSTK are weird, but that might be because these are common diseases
# CM numbers are definitely off






