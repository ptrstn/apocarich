import datetime
import glob
import subprocess
from pathlib import Path

import pandas as pd

from apocarich.settings import (
    CACHE_PATH,
    GROUPED_CACHE_PATH,
    DATE_FORMAT,
    EXPORTED_CSV_FILE_NAME,
)
from apocarich.utils import is_weekend, create_empty_file, is_today

pd.set_option("display.max_rows", 10)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)


def remove_all_may_be_incomplete_files(base_path="data"):
    for filename in glob.iglob(f"{base_path}/**", recursive=True):
        if Path(filename).exists():  # filter dirs
            if "MAY_BE_INCOMPLETE" in filename:
                print(f"Removing {filename}...")
                Path(filename).unlink()


def cache_dataframe(df):
    CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_pickle(CACHE_PATH)


def load_dataframe_cache():
    return pd.read_pickle(CACHE_PATH)


def cache_grouped_dataframe(df):
    GROUPED_CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_pickle(GROUPED_CACHE_PATH)


def load_grouped_dataframe_cache():
    return pd.read_pickle(GROUPED_CACHE_PATH)


def group_per_day(df):
    print("Grouping DataFrame per day...")
    copy = df.copy()
    copy.loc[:, "AveragePrice"] = (copy.StartPrice + copy.EndPrice) / 2
    columns = ["ISIN", "Mnemonic", "SecurityDesc", "SecurityType", "Currency", "Date"]
    mean = copy.groupby(columns).AveragePrice.agg(["mean"])
    volume = copy.groupby(columns).TradedVolume.agg(["sum"])
    trades = copy.groupby(columns).NumberOfTrades.agg(["sum"])

    grouped_df = mean.reset_index().rename(columns={"mean": "price"})
    grouped_df.loc[:, "volume"] = volume["sum"].reset_index()["sum"]
    grouped_df.loc[:, "trades"] = trades["sum"].reset_index()["sum"]

    return grouped_df


def group_per_stonk(df):
    columns = ["ISIN", "Mnemonic", "SecurityDesc", "SecurityType", "Currency"]
    df.groupby(columns)["volume", "trades"].sum()


def read_data_directory(path):
    """
    :param path: path of the csv files
    :return: pandas DataFrame
    """
    print(f"Reading data from {path}...")
    return pd.concat(
        [pd.read_csv(file) for file in Path(path).glob("*.csv")], ignore_index=True
    )


def read_data(market="xetra", base_path="data"):
    path = Path(base_path, f"deutsche-boerse-{market}-pds")

    print("Loading data...")

    return (
        pd.concat(
            [read_data_directory(folder) for folder in path.iterdir()],
            ignore_index=True,
        )
        # .sort_values(by=["Date", "Time", "Mnemonic"], ascending=[False, True, True])
        # .reset_index(drop=True)
    )


def retrieve_aws_data(
    date, trading_platform="xetra", skip_duplicate=True, skip_weekend=True, base_path="data"
):
    if skip_weekend and is_weekend(date):
        print(f"[SKIP]\tSkipping weekend day {date}...")
        return

    target_path = Path(base_path, f"deutsche-boerse-{trading_platform}-pds", date)
    files = sorted([f.stem for f in list(target_path.glob("*.csv"))])

    if skip_duplicate and len(files) > 0:
        if Path(target_path, "MAY_BE_INCOMPLETE").exists():
            print(f"[?]\t{date}\tFound possibly incomplete data. Renewing...")
            Path(target_path, "MAY_BE_INCOMPLETE").unlink()
        else:
            print(f"[SKIP]\tData for {date} already exists. Skipping...")
            return

    command = [
        "aws",
        "s3",
        "sync",
        f"s3://deutsche-boerse-{trading_platform}-pds/{date}",
        f"{target_path}",
        "--no-sign-request",
    ]
    subprocess.run(command, stdout=subprocess.PIPE, universal_newlines=True)

    if is_today(date):
        create_empty_file(Path(target_path, "MAY_BE_INCOMPLETE"))

    print(f"[OK]\t{date}")


def retrieve_all_aws_data(
    start_date="2019-12-01", end_date=None, trading_platform="xetra", base_path="data"
):
    """
    :param trading_platform: "xetra" or "eurex"
    :param start_date: Earliest possible is "2017-06-17" for Xetra and "2017-05-27" for Eurex
    :return:
    """
    start = datetime.datetime.strptime(start_date, DATE_FORMAT)
    if not end_date:
        end = datetime.datetime.now()
    else:
        end = datetime.datetime.strptime(end_date, DATE_FORMAT)

    generated_dates = [
        start + datetime.timedelta(days=x) for x in range(0, (end - start).days + 1)
    ]
    dates = [date.strftime(DATE_FORMAT) for date in generated_dates]

    print(
        f"Retrieving data for days from {start.strftime(DATE_FORMAT)} to {end.strftime(DATE_FORMAT)}...\n"
    )

    for date in dates:
        print(f"Retrieving stock data from {trading_platform} for day {date}...")
        retrieve_aws_data(date, trading_platform, base_path=base_path)


def update_data_csv(base_path="data"):
    path = Path(base_path, EXPORTED_CSV_FILE_NAME)
    print(f"Updating {path}...\n")
    df = read_data(base_path=base_path)

    g = group_per_day(df)
    g.to_csv(path, index=False)
