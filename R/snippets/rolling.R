if (!require("here")) install.packages("here")
library("here")
source(here("rcode", "requirements.R"))

p_load("RcppRoll")
p_load("zoo")

# https://stackoverflow.com/questions/30153835/r-dplyr-rolling-sum

#create data
dg = expand.grid(site = c("Boston","New York"),
                 year = 2000:2004)
dg$animal="dog"
dg$animal[10]="cat";dg$animal=as.factor(dg$animal)
dg$count = rpois(dim(dg)[1], 5) 

dg %>%
  arrange(site,year,animal) %>% 
  group_by(site, animal) %>%
  mutate(roll_sum = roll_sum(count, 2, align = "right", fill = NA)) %>%
  mutate(rollapply_sum =rollapplyr(count, 2, sum, partial = TRUE) )


dg %>%
  arrange(site,year,animal) %>% 
  group_by(site, animal) %>%
  mutate(roll_mean = roll_mean(count, 3, align = "right", fill = NA)) %>%
  mutate(rollapply_mean =rollapplyr(count, 3, mean, partial = TRUE) )
