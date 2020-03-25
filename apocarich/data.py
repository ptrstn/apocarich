import datetime
import subprocess
from pathlib import Path

import pandas as pd
import os
import seaborn as sns

sns.set(color_codes=True)


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


def retrieve_aws_data(trading_platform="xetra", date="2017-06-17", skip_duplicate=True):
    target_path = Path("data", f"deutsche-boerse-{trading_platform}-pds", date)
    files = sorted([f.stem for f in list(target_path.glob("*.csv"))])

    if skip_duplicate and len(files) > 0:
        if Path(target_path, "MAY_BE_INCOMPLETE").exists():
            print("Found possibly incomplete data. Renewing..")
            Path(target_path, "MAY_BE_INCOMPLETE").unlink()
        else:
            print(f"Data for {date} already exists. Skipping...")
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

    date_format = "%Y-%m-%d"
    if datetime.datetime.now().strftime(date_format) == "2020-03-25":
        with open(Path(target_path, "MAY_BE_INCOMPLETE"), "w"):
            pass


def retrieve_all_aws_data(trading_platform="xetra", start_date="2019-12-01"):
    """
    :param trading_platform: "xetra" or "eurex"
    :param start_date: Earliest possible is "2017-06-17" for Xetra AND "2017-05-27" for Eurex
    :return:
    """
    date_format = "%Y-%m-%d"
    # start = datetime.datetime.strptime("2017-06-17", date_format)
    start = datetime.datetime.strptime(start_date, date_format)
    # end = datetime.datetime.strptime("2017-06-19", date_format)
    end = datetime.datetime.now()

    generated_dates = [
        start + datetime.timedelta(days=x) for x in range(0, (end - start).days + 1)
    ]
    dates = [date.strftime(date_format) for date in generated_dates]

    for date in dates:
        print(f"Retrieving stock data form {trading_platform} for day {date}...")
        retrieve_aws_data(trading_platform, date)


def filter_common_stocks(dataframe):
    return dataframe[dataframe.SecurityType == "Common stock"]


def do():
    df = read_data_directory("2019-12-02").pipe(filter_common_stocks)
    df["price"] = df.StartPrice + df.EndPrice / 2
