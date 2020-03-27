#!/usr/bin/env Rscript

if (!require("here")) install.packages("here")
library("here")
source(here("R", "requirements.R"))
source(here("R", "functions.R"))

# https://stackoverflow.com/questions/14167178/passing-command-line-arguments-to-r-cmd-batch
# http://finzi.psych.upenn.edu/R/library/R.utils/html/commandArgs.html

# run: Rscript R/snippets/run.R --abc "A new value" --hi 23 --brumm test --foo bar baz

abc="Ein Defaultwert"
def="Another default value"

cat("\nValue of abc before parsing:\n");
print(abc)

args = commandArgs(trailingOnly=TRUE, asValues = TRUE)

cat("\nargs:\n");
print(args)

# str(args)
keys <- attachLocally(args)

cat("\nkeys:\n");
print(keys)

cat("\nCommand-line arguments attached to global environment:\n");
str(mget(keys, envir=globalenv()))

cat("\nValue of abc after parsing:\n");
print(abc)