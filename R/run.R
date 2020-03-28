#!/usr/bin/env Rscript
# Run example:
# Rscript R/run.R --start 2020-01-03 --end 2020-03-26 --apocalypse 2020-02-05 --numchars 5 --outdir bilder --windowsize 1 --stocktype ETF
#

if (!require("here")) install.packages("here")
library("here")
source(here("R", "requirements.R"))
source(here("R", "settings.R"))
source(here("R", "functions.R"))

start <- DEFAULT_START_DATE
end <- DEFAULT_END_DATE
apocalypse <- DEFAULT_APOCALYPSE_DATE
stocktype <- DEFAULT_STOCK_TYPE
numstocks <- DEFAULT_NUMBER_OF_STOCKS
windowsize <- DEFAULT_WINDOW_SIZE
numchars <- DEFAULT_NUMBER_OF_CHARACTERS
outdir <- DEFAULT_OUTPUT_DIRECTORY
untilrecent <- DEFAULT_UNTIL_MOST_RECENT_DAY
nmosttraded <- DEFAULT_NUMBER_OF_MOST_TRADED_STOCKS
nmostvolume <- DEFAULT_NUMBER_OF_MOST_VOLUME_STOCKS
nolossuntilapo <- DEFAULT_NO_LOSS_UNTIL_APOCALYPSE_DATE

args <- commandArgs(trailingOnly = TRUE, asValues = TRUE)
keys <- attachLocally(args)

data <- read_csv(here("data", "data.csv")) %>%
  filter(Date >= start) %>%
  filter(Date <= end) %>%
  filter(SecurityType == stocktype) %>%
  drop_na(Mnemonic) %>%
  filter_most_volume(nmostvolume) %>%
  filter_most_traded(nmosttraded) %>%
  filter_no_loss_until_apocalypse(nolossuntilapo, apocalypse)

caption <- generate_caption(data, stocktype, apocalypse, windowsize, nmosttraded, nmostvolume, untilrecent, nolossuntilapo)

p <- plot_biggest_losses(
  data,
  stock_type = stocktype,
  number_of_stonks = numstocks,
  window_size = windowsize,
  number_of_characters = numchars,
  apocalypse_date = apocalypse,
  until_most_recent_day = untilrecent,
  caption = caption
) 


file_name <- paste(stocktype, "_from_", start, "_to_", end, "_apoc_", apocalypse, "__", numstocks, "s_", windowsize, "w", sep = "")
file_name <- str_replace(file_name, " ", "_")

# Save PNG
png_path <- file.path(outdir, "png", paste(file_name, ".png", sep = ""))
dir.create(dirname(png_path), showWarnings = FALSE, recursive = TRUE)
ggsave(p, filename = png_path, width = 16, height = 9)
cat(paste("\nCreated new file:", png_path, "\n"))

fig <- ggplotly(p)

# Save HTML
html_file_name <- paste(file_name, ".html", sep = "")
html_path <- file.path(outdir, "html", html_file_name)
dir.create(dirname(html_path), showWarnings = FALSE, recursive = TRUE)
withr::with_dir(dirname(html_path), htmlwidgets::saveWidget(as_widget(fig), file = html_file_name))

cat(paste("Created new file:", html_path, "\n"))
