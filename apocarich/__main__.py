from apocarich.core import get_stock_prices


def main():
    symbol = "DAX"
    print(f"Getting stock prices for {symbol}...\n")
    print(get_stock_prices(symbol))


if __name__ == "__main__":
    main()
