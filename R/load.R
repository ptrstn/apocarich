if (!require("here")) install.packages("here")
library("here")
source(here("rcode", "requirements.R"))

data <- read_csv("data/data.csv") %>% select(-X1)
data <- data %>% filter(Date > "2019-11-01")
data <- data %>% filter(Date > "2020-02-01")

# plot_most_traded_stonks(data, 30)
# plot_most_traded_etfs(data, 30)

# Highest loss
start_date <- "2019-11-04"
apocalypse_date <- "2020-02-18"
low_date <- "2020-03-25"

tmp <- data %>%
  filter(Date == start_date | Date == apocalypse_date | Date == low_date) %>%
  filter(SecurityType == "Common stock")

# by_stonk_trades = tmp %>%
#  group_by(ISIN, Mnemonic, SecurityDesc, SecurityType, Currency) %>%
#  summarise(trades = sum(trades)) %>%
#  arrange(desc(trades)) %>% filter(trades > 100000)

wide <- tmp %>%
  #  filter(ISIN %in% by_stonk_trades$ISIN)
  select(-volume, -trades) %>%
  spread(Date, price)


# wide <- tmp %>%
#  select(-volume, -trades) %>%
#  spread(Date, price)

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
d$SecurityDesc <- str_sub(d$SecurityDesc, 1, 20)
d %>%
  ggplot(aes(Date, price)) +
  geom_line() +
  facet_wrap(vars(paste(Mnemonic, SecurityDesc)), scales = "free") +
  ggtitle("30 of the biggest loosers")

# Wert am anfang ermitteln
# Wert an apo date ermitteln
# Wert heute ermitteln
