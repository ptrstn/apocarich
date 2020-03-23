import requests
import pandas

API_KEY = "demo"


def test_api():
    symbol = "FRA"
    function = "TIME_SERIES_DAILY"
    outputsize = "full"  # "compact" or "full"

    print(f"Requesting stock prices for {symbol}...")

    response = requests.get(
        f"https://www.alphavantage.co/query?function={function}&outputsize={outputsize}&symbol={symbol}&apikey={API_KEY}"
    )
    assert (
        response.status_code == 200
    ), f"Response failed, status code {response.status_code}"
    result = response.json()
    assert "Time Series (Daily)" in result
    time_series = result["Time Series (Daily)"]

    days = sorted(time_series.keys())
    print(f"Number of days: {len(days)}")
    print(f"Ranging from {min(days)} to {max(days)}")

    print(time_series[days[0]])


def _time_series_response_to_data_frame(time_series, symbol):
    """
    :param time_series: "Time Series (Daily)" dictionary
    :return: pandas data frame
    """
    df = pandas.DataFrame(time_series)
    df = df.transpose()
    df["symbol"] = symbol
    df.rename(
        columns={
            "1. open": "open",
            "2. high": "high",
            "3. low": "low",
            "4. close": "close",
            "5. volume": "volume",
        },
        inplace=True,
    )
    return df


def get_stock_prices(
    symbol, size="compact",
):
    """
    :param symbol: e.g. "MSFT"
    :param size: "compact" (last 100) or "full"
    :return: pandas data frame
    """
    function = "TIME_SERIES_DAILY"

    response = requests.get(
        f"https://www.alphavantage.co/query?function={function}&outputsize={size}&symbol={symbol}&apikey={API_KEY}"
    )
    assert (
        response.status_code == 200
    ), f"Response failed, status code {response.status_code}"
    result = response.json()
    assert "Error Message" not in result, f"Invalid symbol: '{symbol}'"
    assert "Time Series (Daily)" in result
    time_series = result["Time Series (Daily)"]
    return _time_series_response_to_data_frame(time_series, symbol)
