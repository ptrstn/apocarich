# Try to load package manager "pacman" and install it if loading failed
if (!require("pacman")) install.packages("pacman")
library("pacman")

p_load("here")

p_load("tidyverse")
p_load("readr")
p_load("dplyr")
p_load("tidyr")
p_load("stringr")
p_load("ggplot2")
p_load("plotly")

p_load("RcppRoll")
p_load("zoo")

p_load("styler")
p_load("prettycode")

p_load("R.utils")
