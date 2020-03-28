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
  drop_na(Mnemonic)

untilrecent <- TRUE
nmosttraded <- 200
windowsize <- 15
nolossuntilapo <- TRUE

min_date = min(data$Date)
max_date = max(data$Date)

caption = ""
caption <- paste("Filtered by ", stocktype, "s. ", sep = "")
if(!is.null(nmosttraded))
  caption <- paste(caption, "Consdering only the top ", nmosttraded, " companies by trades. ", sep = "")
if(!is.null(nmostvolume))
  caption <- paste(caption, "Consdering only the top ", nmostvolume, " companies by volume. ", sep = "")
if(untilrecent){
  caption <- paste(caption, "Filtered companies with biggest drop until today. ", sep = "")
} else {
  caption <- paste(caption, "Filtered companies with biggest drop until after ", apocalypse, ". ", sep = "")
}

caption <- paste(caption, "\nApocalypse day is ", apocalypse, ". ", sep="")
if(nolossuntilapo)
  caption <- paste(caption, "Removed all stocks with no gain from ", min_date, " until apocalypse day. ", sep = "")
caption <- paste(caption, "Window size for moving average is ", windowsize, ".\n", sep = "")

caption <- paste(caption, "Dates are from ", min_date, " until ", max_date, ". ", sep="")
caption <- paste(caption, "Data source is Xetra.\n", sep="")

if(!is.null(nmosttraded)){
  most_traded_isins <- data %>% 
    group_by(ISIN, Mnemonic, SecurityDesc) %>% 
    summarise(trade_sum = sum(trades)) %>% 
    ungroup() %>%
    arrange(desc(trade_sum)) %>%
    slice(1:nmosttraded) %>%
    select(ISIN) %>%
    pull()
  
  data <- data %>% filter(ISIN %in% most_traded_isins)
}

if(!is.null(nmostvolume)){
  most_volume_isins <- data %>% 
    group_by(ISIN, Mnemonic, SecurityDesc) %>% 
    summarise(trade_sum = sum(volume)) %>% 
    ungroup() %>%
    arrange(desc(trade_sum)) %>%
    slice(1:nmostvolume) %>%
    select(ISIN) %>%
    pull()
  
  data <- data %>% filter(ISIN %in% most_volume_isins)
}

if(nolossuntilapo){
  # Filter data to all companies with no loss until apocalypse day
  tmp <- data %>% 
    filter(Date <= apocalypse)  %>%
    add_moving_average_column(window_size = windowsize) %>%
    group_by(Mnemonic, SecurityDesc) 
  
  tmp_apocalypse <- tmp %>%
    top_n(1, Date) %>%
    mutate(date_type = "apocalypse")
  
  tmp_before <- tmp %>%
    top_n(-1, Date) %>%
    mutate(date_type = "before")
  
  tmp_difference <- bind_rows(tmp_before, tmp_apocalypse) %>% 
    select(-volume, -trades, -price, -Date) %>% 
    ungroup() %>%
    spread(date_type, `Moving average`) %>%
    mutate(apoca_difference = apocalypse/before)
  
  no_loss_isins <- bind_rows(tmp_before, tmp_apocalypse) %>% 
    select(-volume, -trades, -price, -Date) %>% 
    ungroup() %>%
    spread(date_type, `Moving average`) %>%
    mutate(apoca_difference = apocalypse/before) %>%
    filter(apoca_difference >= 1) %>%
    select(ISIN) %>% 
    pull()
  
  data <- data %>% filter(ISIN %in% no_loss_isins)
}


p <- plot_biggest_losses(
  data,
  stock_type = stocktype,
  number_of_stonks = numstocks,
  window_size = windowsize,
  number_of_characters = numchars,
  apocalypse_date = apocalypse,
  until_most_recent_day = untilrecent
) + labs(caption = caption)

p 

# file_name <- paste(stocktype, "_from_", start, "_to_", end, "_apoc_", apocalypse, "__", numstocks, "s_", windowsize, "w", sep = "")
# file_name <- str_replace(file_name, " ", "_")
# 
# # Save PNG
# png_path <- file.path(outdir, "png", paste(file_name, ".png", sep=""))
# dir.create(dirname(png_path), showWarnings = FALSE, recursive = TRUE)
# ggsave(p, filename = png_path,  width = 16, height = 9)
# cat(paste("\nCreated new file:", png_path, "\n"))
# 
# fig <- ggplotly(p)
# 
# # Save HTML
# html_file_name <- paste(file_name, ".html", sep="")
# html_path <- file.path(outdir, "html", html_file_name)
# dir.create(dirname(html_path), showWarnings = FALSE, recursive = TRUE)
# withr::with_dir(dirname(html_path), htmlwidgets::saveWidget(as_widget(fig), file=html_file_name))
# 
# cat(paste("Created new file:", html_path, "\n"))
