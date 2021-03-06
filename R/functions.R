if (!require("here")) install.packages("here")
library("here")
source(here("R", "requirements.R"))
source(here("R", "settings.R"))

# Filter most important stonks
get_most_traded_ISINs <- function(data, number_of_stonks = DEFAULT_NUMBER_OF_STOCKS) {
  by_stonk_trades <- data %>%
    group_by(ISIN, Mnemonic, SecurityDesc) %>%
    summarise(trades = sum(trades)) %>%
    arrange(desc(trades))

  by_stonk_trades$ISIN[0:as.integer(number_of_stonks)]
}

# normal stonks
plot_most_traded <- function(d, number_of_stonks = DEFAULT_NUMBER_OF_STOCKS, title) {
  most_traded_ISINs <- get_most_traded_ISINs(d, number_of_stonks)
  most_traded_data <- filtered_data %>% filter(ISIN %in% most_traded_ISINs)
  most_traded_data %>%
    ggplot(aes(Date, price)) +
    geom_line() +
    facet_wrap(vars(Mnemonic), scales = "free") +
    ggtitle(title)
}


# normal stonks
plot_most_traded_stonks <- function(data, number_of_stonks = DEFAULT_NUMBER_OF_STOCKS) {
  filtered_data <- data %>% filter(SecurityType == "Common stock")
  title <- paste(number_of_stonks, "of the most traded stonks")
  plot_most_traded(d, number_of_stonks, title)
}


# ETFs
plot_most_traded_etfs <- function(data, number_of_stonks = DEFAULT_NUMBER_OF_STOCKS) {
  filtered_data <- data %>% filter(SecurityType == "ETF")
  title <- paste(number_of_stonks, "of the most traded ETFs")
  plot_most_traded(d, number_of_stonks, title)
}


plot_biggest_loosers <- function(data,
                                 start_date,
                                 middle_date,
                                 end_date,
                                 number_of_characters) {
  tmp <- data %>%
    filter(Date == start_date | Date == apocalypse_date | Date == low_date) %>%
    filter(SecurityType == "Common stock")

  wide <- tmp %>%
    #  filter(ISIN %in% by_stonk_trades$ISIN)
    select(-volume, -trades) %>%
    spread(Date, price)

  old_names <- names(wide)
  old_names[6] <- "beginning"
  old_names[7] <- "middle"
  old_names[8] <- "end"
  names(wide) <- old_names

  wide <- wide %>%
    drop_na(beginning) %>%
    drop_na(middle) %>%
    drop_na(end)

  wide <- wide %>% filter(middle / beginning > 0.9)
  wide <- wide %>%
    mutate(loss = 1 - end / middle) %>%
    arrange(desc(loss))

  biggest_looser_ISINs <- wide$ISIN[0:30]
  biggest_looser_name <- wide$Mnemonic[0:30]

  filtered_data <- data %>% filter(ISIN %in% biggest_looser_ISINs)
  filtered_data$Mnemonic <- factor(filtered_data$Mnemonic, levels = biggest_looser_name)

  filtered_data$SecurityDesc <- str_sub(filtered_data$SecurityDesc, 1, as.integer(number_of_characters))

  filtered_data %>%
    ggplot(aes(Date, price)) +
    geom_line() +
    facet_wrap(vars(paste(Mnemonic, SecurityDesc)), scales = "free") +
    ggtitle("30 of the biggest loosers")
}

add_moving_average_column <- function(data, window_size) {
  data %>%
    arrange(Mnemonic, SecurityDesc, Date) %>%
    group_by(Mnemonic, SecurityDesc) %>%
    mutate(`Moving average` = rollapplyr(price, as.integer(window_size), mean, partial = TRUE))
}

gather_price_types <- function(data) {
  data %>% gather(`Price type`, Value, price, `Moving average`)
}

plot_moving_average <- function(data, stock, window_size, number_of_characters) {
  description <- data %>%
    filter(Mnemonic == stock) %>%
    select(SecurityDesc) %>%
    first() %>%
    first()

  title <- paste("[", stock, "] ", str_sub(description, 1, number_of_characters), sep = "")


  data %>%
    filter(Mnemonic == stock) %>%
    add_moving_average_column(window_size = window_size) %>%
    gather_price_types() %>%
    ggplot(aes(Date, Value, colour = `Price type`)) +
    geom_line() +
    ggtitle(title) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
    scale_color_brewer(palette = "Set1")
}

add_loss_column <- function(data, apocalypse_date, window_size, until_most_recent_day) {
  grouped_data <- data %>%
    add_moving_average_column(window_size) %>%
    group_by(Mnemonic, SecurityDesc)

  before_max_tibble <- grouped_data %>%
    filter(Date < apocalypse_date) %>%
    mutate(maximum = max(`Moving average`)) %>%
    select(ISIN, Mnemonic, SecurityDesc, maximum) %>%
    distinct()

  after_min_tibble <- grouped_data %>%
    filter(Date >= apocalypse_date) %>%
    mutate(minimum = min(`Moving average`)) %>%
    select(ISIN, Mnemonic, SecurityDesc, minimum) %>%
    distinct()
  
  most_recent_tibble <- grouped_data %>%
    filter(Date >= apocalypse_date) %>%
    mutate(recent_value = last(`Moving average`)) %>%
    select(ISIN, Mnemonic, SecurityDesc, recent_value) %>%
    distinct()
  
  #recent_value_tibble <- data %>% filter(Date == max_date) %>%
  #  select(ISIN, Mnemonic, SecurityDesc, price) %>%
  #  mutate(recent_value = price) %>%
  #  select(-price)
  
  new_tibble <- before_max_tibble %>%
    full_join(after_min_tibble, by = c("ISIN", "Mnemonic", "SecurityDesc")) %>%
    full_join(most_recent_tibble, by = c("ISIN", "Mnemonic", "SecurityDesc")) 
  
  if(until_most_recent_day){
    new_tibble <- new_tibble %>%
      mutate(loss = 1 - recent_value / maximum)
  } else {
    new_tibble <- new_tibble %>%
      mutate(loss = 1 - minimum / maximum)
  }
  
  data %>% left_join(new_tibble, by = c("ISIN", "Mnemonic", "SecurityDesc")) %>% ungroup()
  # 266.252
}

plot_biggest_losses <- function(data,
                                stock_type = DEFAULT_STOCK_TYPE,
                                number_of_stonks = DEFAULT_NUMBER_OF_STOCKS,
                                window_size = DEFAULT_WINDOW_SIZE,
                                number_of_characters = DEFAULT_NUMBER_OF_CHARACTERS,
                                apocalypse_date = DEFAULT_APOCALYPSE_DATE,
                                until_most_recent_day = DEFAULT_UNTIL_MOST_RECENT_DAY,
                                caption=waiver()) {
  filtered_data <- data %>%
    filter(SecurityType == stock_type) %>%
    add_loss_column(apocalypse_date = apocalypse_date, window_size = window_size, until_most_recent_day = until_most_recent_day) %>%
    arrange(desc(loss))

  mnemonics <- filtered_data %>%
    distinct(Mnemonic) %>% # remove duplicates (same stock different different day)
    ungroup() %>% # undo grouping
    select(Mnemonic) %>% # Onlz 1 column
    slice(1:as.integer(number_of_stonks)) %>% # only first few rows
    pull() # Column to vector

  filtered_data <- filtered_data %>% filter(Mnemonic %in% mnemonics)
  filtered_data$Mnemonic <- factor(filtered_data$Mnemonic, levels = unique(filtered_data$Mnemonic))

  filtered_data$stock_label <- paste(
    "[", filtered_data$Mnemonic, "] ",
    str_sub(filtered_data$SecurityDesc, 1, number_of_characters),
    " (-", format(round(filtered_data$loss, 4) * 100), "%)",
    sep = ""
  )
  filtered_data$stock_label <- factor(filtered_data$stock_label, levels = unique(filtered_data$stock_label))

  widened_data <- filtered_data %>%
    add_moving_average_column(window_size=window_size) %>%
    gather_price_types()
  
  tmp_data <- widened_data %>% filter(`Price type` == "Moving average") %>% drop_na()
  
  if(until_most_recent_day){
    tmp_data <- tmp_data[tmp_data$Value==tmp_data$recent_value | tmp_data$Value==tmp_data$maximum, ]
  } else {
    tmp_data <- tmp_data[tmp_data$Value==tmp_data$minimum | tmp_data$Value==tmp_data$maximum, ]
  }
  tmp_data["Price type"] = "Extrema"
  
  apocalypse_day_data <- widened_data %>% 
    select(ISIN, Mnemonic, SecurityDesc, Date, `Price type`, Value, stock_label) %>%
    filter(`Price type` == "Moving average") %>%
    filter(Date <= apocalypse_date) %>%
    group_by(ISIN, Mnemonic, SecurityDesc, stock_label) %>%
    top_n(1, Date) %>%
    mutate(`Price type` = "Apocalypse day")
  
  title <- paste("Biggest losses in", stock_type)
  
  if(until_most_recent_day){
    title <- paste(title, "(until most recent day)")
    
  }
  
  widened_data %>%
    ggplot(aes(Date, Value, colour = `Price type`)) +
    geom_line() +
    ggtitle(title) +
    theme(plot.title = element_text(face = "bold", hjust = 0.5)) +
    scale_color_brewer(palette = "Set1") +
    geom_point(data=tmp_data, aes(Date, Value)) +
    geom_point(data=apocalypse_day_data, aes(Date, Value)) +
    facet_wrap(vars(stock_label), scales = "free") + 
    labs(caption = caption)
}


generate_caption <- function(data, stocktype, apocalypse, windowsize, nmosttraded, nmostvolume, untilrecent, nolossuntilapo){
  caption <- ""
  
  min_date <- min(data$Date)
  max_date <- max(data$Date)
  
  caption <- paste("Filtered by ", stocktype, "s. ", sep = "")
  if (!is.null(nmosttraded)) {
    caption <- paste(caption, "Consdering only the top ", nmosttraded, " companies by trades. ", sep = "")
  }
  if (!is.null(nmostvolume)) {
    caption <- paste(caption, "Consdering only the top ", nmostvolume, " companies by volume. ", sep = "")
  }
  if (untilrecent) {
    caption <- paste(caption, "Filtered companies with biggest drop until today. ", sep = "")
  } else {
    caption <- paste(caption, "Filtered companies with biggest drop until after ", apocalypse, ". ", sep = "")
  }
  
  caption <- paste(caption, "\nApocalypse day is ", apocalypse, ". ", sep = "")
  if (nolossuntilapo) {
    caption <- paste(caption, "Removed all stocks with no gain from ", min_date, " until apocalypse day. ", sep = "")
  }
  caption <- paste(caption, "Window size for moving average is ", windowsize, ".\n", sep = "")
  
  caption <- paste(caption, "Dates are from ", min_date, " until ", max_date, ". ", sep = "")
  caption <- paste(caption, "Data source is Xetra.\n", sep = "")
  caption
}

filter_most_traded <- function(data, nmosttraded){
  if (!is.null(nmosttraded)) {
    most_traded_isins <- data %>%
      group_by(ISIN, Mnemonic, SecurityDesc) %>%
      summarise(trade_sum = sum(trades)) %>%
      ungroup() %>%
      arrange(desc(trade_sum)) %>%
      slice(1:as.integer(nmosttraded)) %>%
      select(ISIN) %>%
      pull()
    
    data %>% filter(ISIN %in% most_traded_isins)
  } else {
    data
  }
}


filter_most_volume <- function(data, nmosttraded){
  if (!is.null(nmostvolume)) {
    most_volume_isins <- data %>%
      group_by(ISIN, Mnemonic, SecurityDesc) %>%
      summarise(trade_sum = sum(volume)) %>%
      ungroup() %>%
      arrange(desc(trade_sum)) %>%
      slice(1:as.integer(nmostvalue)) %>%
      select(ISIN) %>%
      pull()
    
    data %>% filter(ISIN %in% most_volume_isins)
  } else {
    data
  }
}

filter_no_loss_until_apocalypse <- function(data, nolossuntilapo, apocalypse, max_ratio){
  if (nolossuntilapo) {
    # Filter data to all companies with no loss until apocalypse day
    tmp <- data %>%
      filter(Date <= apocalypse) %>%
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
      mutate(apoca_difference = apocalypse / before)
    
    no_loss_isins <- bind_rows(tmp_before, tmp_apocalypse) %>%
      select(-volume, -trades, -price, -Date) %>%
      ungroup() %>%
      spread(date_type, `Moving average`) %>%
      mutate(apoca_difference = apocalypse / before) %>%
      filter(apoca_difference >= max_ratio) %>%
      select(ISIN) %>%
      pull()
    
    data %>% filter(ISIN %in% no_loss_isins)
  } else {
    data
  }
}