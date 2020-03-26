if (!require("here")) install.packages("here")
library("here")
source(here("rcode", "requirements.R"))

# Filter most important stonks
get_most_traded_ISINs <- function(data, number_of_stonks = 20) {
  by_stonk_trades <- data %>%
    group_by(ISIN, Mnemonic, SecurityDesc, SecurityType, Currency) %>%
    summarise(trades = sum(trades)) %>%
    arrange(desc(trades))
  
  by_stonk_trades$ISIN[0:number_of_stonks]
}

# normal stonks
plot_most_traded <- function(d, number_of_stonks = 20, title) {
  most_traded_ISINs <- get_most_traded_ISINs(d, number_of_stonks)
  most_traded_data <- d %>% filter(ISIN %in% most_traded_ISINs)
  most_traded_data %>%
    ggplot(aes(Date, price)) +
    geom_line() +
    facet_wrap(vars(Mnemonic), scales = "free") +
    ggtitle(title)
}


# normal stonks
plot_most_traded_stonks <- function(data, number_of_stonks = 20) {
  d <- data %>% filter(SecurityType == "Common stock")
  title <- paste(number_of_stonks, "of the most traded stonks")
  plot_most_traded(d, number_of_stonks, title)
}


# ETFs
plot_most_traded_etfs <- function(data, number_of_stonks = 20) {
  d <- data %>% filter(SecurityType == "ETF")
  title <- paste(number_of_stonks, "of the most traded ETFs")
  plot_most_traded(d, number_of_stonks, title)
}


plot_biggest_loosers <- function(data,
                                 start_date = "2019-11-04",
                                 middle_date = "2020-02-18",
                                 end_date = "2020-03-25") {
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
  
  d <- data %>% filter(ISIN %in% biggest_looser_ISINs)
  d$Mnemonic <- factor(d$Mnemonic, levels = biggest_looser_name)
  
  NUMBER_OF_CHARACTERS <- 20 # For the label
  d$SecurityDesc <- str_sub(d$SecurityDesc, 1, NUMBER_OF_CHARACTERS)
  
  d %>%
    ggplot(aes(Date, price)) +
    geom_line() +
    facet_wrap(vars(paste(Mnemonic, SecurityDesc)), scales = "free") +
    ggtitle("30 of the biggest loosers")
}

add_moving_average_column <- function(data, window_size){
  data %>% 
    arrange(Mnemonic, SecurityDesc, SecurityType, Currency) %>% 
    mutate(`Moving average` = rollapplyr(price, window_size, mean, partial=TRUE))
}

gather_price_types <- function(data){
  data %>% gather(`Price type`, Value, price, `Moving average`)
}

plot_moving_average <- function(data, stock, window_size = 15){
  description = data %>% filter(Mnemonic == stock) %>% select(SecurityDesc) %>% first() %>% first()
  
  NUMBER_OF_CHARACTERS <- 20 # For the label
  title = paste("[", stock, "] ", str_sub(description, 1, NUMBER_OF_CHARACTERS), sep = "")
  
  
  data %>% 
    filter(Mnemonic == stock) %>%
    add_moving_average_column(window_size) %>% 
    gather_price_types %>%
    ggplot(aes(Date, Value, colour=`Price type`)) + 
    geom_line() + 
    ggtitle(title) +
    theme(plot.title = element_text(face = "bold", hjust=0.5)) + 
    scale_color_brewer(palette="Set1")
}

add_loss_column <- function(data, window_size = 15){
  d <- data %>%
    add_moving_average_column(window_size) %>%
    group_by(Mnemonic, SecurityDesc)
  
  before <- d %>% filter(Date < "2020-02-18")
  after <- d %>% filter(Date >= "2020-02-18")
  
  before <- before %>%
    mutate(maximum = max(`Moving average`)) 
  
  after <- after %>% 
    mutate(minimum = min(`Moving average`))
  
  
  
    mutate(loss = 1 - minimum/maximum)
}
