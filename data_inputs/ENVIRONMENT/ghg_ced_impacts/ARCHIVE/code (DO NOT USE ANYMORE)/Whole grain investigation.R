# whole grains


# need to read in both_days


wg <- both_days %>% filter(str_detect(foodcode, "^5"))

# create whole grain proportion

wg1 <- wg %>% 
  rowwise() %>% 
  mutate(wg_prop = gr_whole / sum(gr_whole, gr_refined),
                     wg_yes = ifelse(wg_prop > 0.50, 1, 0)) %>% 
  ungroup()

table(wg1$wg_yes)

wg1 %>% filter(wg_yes == 1) %>% select(foodcode, description) %>% distinct() %>% View()

wg1 %>% select(foodcode, description, wg_yes) %>% distinct() %>% arrange(foodcode) %>% View() #1907

wg1 %>% select(foodcode, wg_yes) %>% distinct() %>% arrange(foodcode) %>% View() #1748

wg1 %>% select(foodcode) %>% distinct() %>% View() #1728

all_ids <- wg1 %>% select(foodcode) %>% distinct() %>% unlist() %>% as.vector() #1728

wg1 %>% select(foodcode, description) %>% distinct() %>% View() #1888

# which ones have same foodcode but different description?
my_sub <- wg1 %>% select(foodcode, description) %>% distinct() #1888 rows

my_sub %>% select(foodcode) %>% distinct() %>% nrow() #1728 rows

# this means that there are 1728 unique IDs
subset(my_sub, duplicated(my_sub$foodcode)) %>% View()


# check one
wg1 %>% filter(foodcode == "58165020") %>% View()

wg1 %>% filter(foodcode == "53520120") %>% View()

# these look fine

# need to identify which foods are coded as both wg and not wg

# Part A

# then make a decision for those 
# (decision = if the food item is coded as 
# wg_yes in more than 50% of instances, then it's manually coded as whole grain (ie, wg_yes_manual = 1))


# find duplicated rows
# x <- wg1 %>% select(foodcode, description, wg_yes) %>% distinct() %>% arrange(foodcode) %>% select(-(wg_yes))

x <- wg1 %>% select(foodcode, wg_yes) %>% distinct() %>% arrange(foodcode) %>% select(-(wg_yes))


duplicated(x)

subset(x, duplicated(x))

dupe_ids <- subset(x, duplicated(x)) %>% unlist() %>% as.vector()

wg1 %>% filter(foodcode %in% dupe_ids) %>% arrange(foodcode) %>% View()

x %>% filter(foodcode %in% dupe_ids) %>% arrange(foodcode) %>% distinct() %>% View()


# then i think I'll just assign all of these whole grains

my_list <- list()

# i = 1

for (i in 1:length(dupe_ids)) {
  
  dat <- wg1 %>% filter(foodcode == paste0(dupe_ids[i]))
  
  my_list[[i]] <-   dat %>% 
    group_by(foodcode, description) %>% 
    summarise(my_prop = sum(wg_yes, na.rm = TRUE) / nrow(dat)) %>% 
    mutate(wg_yes = ifelse(my_prop > 0.5, 1, 0))
  
}

wg_table_a <- bind_rows(my_list)

wg_table_a %>% select(foodcode) %>% distinct()


# Ugh there are two different descriptions for foodcode 52104040
# Manually remove Biscuit, wheat because it is less representative

wg1 %>% filter(foodcode == "52104040") %>% arrange(foodcode) %>% View()

wg_table_a_1 <- wg_table_a %>% filter(description != "Biscuit, wheat")

wg_table_a_2 <- wg_table_a_1 %>% select(-c(description, my_prop))


# Part b

nondupe_ids <- all_ids[!(all_ids %in% dupe_ids)]

wg_table_b <- 
  wg1 %>% 
  filter(foodcode %in% nondupe_ids) %>% 
  select(foodcode, wg_yes) %>% 
  distinct()

subset(wg_table_b, duplicated(wg_table_b$foodcode)) #none

# join the two tables

wg_final <- rbind(wg_table_a_2, wg_table_b) %>% arrange(foodcode)

wg_final1 <- 
  wg_final %>% 
  mutate(Foodgroup = ifelse(wg_yes == 1, "gr_whole", "gr_refined")) %>% 
  select(-wg_yes)

# export

write_csv(wg_final1, "in/Environmental impact (Brooke)/raw data/Food_to_FNDDS_mapping_WHOLE_GRAINS_ONLY_09-04-23.csv")
