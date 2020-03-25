from apocarich.core import get_stock_prices
from apocarich.visual import visualize_data_frame


def main():
    symbol = "DAX"
    print(f"Getting stock prices for {symbol}...\n")
    df = get_stock_prices(symbol)
    print(f"Visualizing data frame...\n")
    visualize_data_frame(df, symbol)


if __name__ == "__main__":
    main()
