import datetime
import glob
import subprocess
from pathlib import Path

import pandas as pd
import os
import seaborn as sns

sns.set(color_codes=True)

DATE_FORMAT = "%Y-%m-%d"


def is_weekend(date_string):
    date = datetime.datetime.strptime(date_string, DATE_FORMAT)
    return date.weekday() >= 5


def is_today(date_string):
    return datetime.datetime.now().strftime(DATE_FORMAT) == date_string


def create_empty_file(path):
    with open(path, "w"):
        pass


def remove_all_may_be_incomplete_files():
    for filename in glob.iglob("data/**", recursive=True):
        if os.path.isfile(filename):  # filter dirs
            if "MAY_BE_INCOMPLETE" in filename:
                print(f"Removing {filename}...")
                Path(filename).unlink()


def read_data_directory(
    date=None, base_path="data", market="deutsche-boerse-xetra-pds"
):
    """
    :param date: e.g. "2020-03-20, latest if None
    :param base_path: data base path
    :param market: "deutsche-boerse-xetra-pds" or "deutsche-boerse-eurex-pds"
    :return: pandas data frame
    """
    if not date:
        dates = os.listdir(os.path.join(base_path, market))
        date = sorted(dates, reverse=True)[0]

    path = os.path.join(base_path, market, date)
    return pd.concat(
        [
            pd.read_csv(os.path.join(path, file))
            for file in os.listdir(path)
            if file.endswith(".csv")
        ]
    )


def retrieve_aws_data(
    date, trading_platform="xetra", skip_duplicate=True, skip_weekend=True
):
    if skip_weekend and is_weekend(date):
        print(f"[SKIP]\tSkipping weekend day {date}...")
        return

    target_path = Path("data", f"deutsche-boerse-{trading_platform}-pds", date)
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


def retrieve_all_aws_data(start_date="2019-12-01", trading_platform="xetra"):
    """
    :param trading_platform: "xetra" or "eurex"
    :param start_date: Earliest possible is "2017-06-17" for Xetra AND "2017-05-27" for Eurex
    :return:
    """
    start = datetime.datetime.strptime(start_date, DATE_FORMAT)
    end = datetime.datetime.now()

    generated_dates = [
        start + datetime.timedelta(days=x) for x in range(0, (end - start).days + 1)
    ]
    dates = [date.strftime(DATE_FORMAT) for date in generated_dates]

    for date in dates:
        print(f"Retrieving stock data form {trading_platform} for day {date}...")
        retrieve_aws_data(date, trading_platform)


def filter_common_stocks(dataframe):
    return dataframe[dataframe.SecurityType == "Common stock"]


def do():
    df = read_data_directory("2019-12-02").pipe(filter_common_stocks)
    df["price"] = df.StartPrice + df.EndPrice / 2


def main():
    start_date = "2019-11-01"
    retrieve_all_aws_data(start_date=start_date)
