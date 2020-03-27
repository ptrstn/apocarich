if (!require("here")) install.packages("here")
library("here")
source(here("R", "requirements.R"))

style_file(here("R", "requirements.R"))
style_file(here("R", "defaults.R"))
style_file(here("R", "functions.R"))
style_file(here("R", "run.R"))
style_file(here("R", "snippets", "style.R"))
