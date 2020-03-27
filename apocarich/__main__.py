import argparse

from apocarich.core import get_stock_prices
from apocarich.data import retrieve_all_aws_data, update_data_csv
from apocarich.visual import visualize_data_frame
from apocarich import __version__


def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Analyzing the stock market",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=30),
    )

    parser.add_argument(
        "--version", action="version", version="%(prog)s {}".format(__version__)
    )

    retrieving_group = parser.add_argument_group("Retrieving data from Xetra")

    retrieving_group.add_argument(
        "--retrieve-data",
        help="Retrieve data from Xetra using the Amazon aws-cli",
        action="store_true",
    )

    retrieving_group.add_argument(
        "--start",
        metavar="DATE",
        default="2019-11-01",
        help="Start date (default is 2019-11-01)",
    )

    retrieving_group.add_argument(
        "--end", metavar="DATE", default=None, help="End date (default is today)"
    )

    updating_group = parser.add_argument_group(
        "Updating exported data.csv by retrieved data"
    )

    updating_group.add_argument(
        "--update-csv",
        help="Generates an updated data.csv by regrouping previously retrieved data",
        action="store_true",
    )

    # visual_group = parser.add_argument_group(
    #    "Visualize data"
    # )

    # visual_group.add_argument(
    #    "--plot-csv",
    #    help="Generates an updated data.csv by regrouping previously retrieved data",
    #    action="store_true",
    # )

    return parser.parse_args()


def visualize_stock_symbol(symbol="DAX"):
    print(f"Getting stock prices for {symbol}...\n")
    df = get_stock_prices(symbol)
    print(f"Visualizing data frame...\n")
    visualize_data_frame(df, symbol)


def main():
    args = parse_arguments()

    print("Welcome to the apocalyptic stock market analyzer!\n\n")

    if args.retrieve_data:
        print("Retrieving data :-)")
        retrieve_all_aws_data(start_date=args.start, end_date=args.end)
    elif args.update_csv:
        update_data_csv()


if __name__ == "__main__":
    main()
