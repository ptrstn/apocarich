from apocarich.core import get_stock_prices


def main():
    symbol = "MSFT"
    print(f"Getting stock prices for {symbol}...\n")
    print(get_stock_prices("MSFT"))


if __name__ == "__main__":
    main()
