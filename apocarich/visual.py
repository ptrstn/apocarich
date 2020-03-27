import plotly.graph_objects as go

from apocarich.alphavantage import get_stock_prices


def visualize_data_frame(df, title=""):
    data = [
        go.Candlestick(
            x=df.date, open=df.open, high=df.high, low=df.low, close=df.close
        )
    ]
    fig = go.Figure(data=data)

    fig.update_layout(
        title={
            "text": title,
            "y": 0.9,
            "x": 0.5,
            "xanchor": "center",
            "yanchor": "top",
        },
        font=dict(family="Courier New, monospace", size=20, color="#7f7f7f"),
    )
    fig.show()


def visualize_stock_symbol(symbol="DAX"):
    print(f"Getting stock prices for {symbol}...\n")
    df = get_stock_prices(symbol)
    print(f"Visualizing data frame...\n")
    visualize_data_frame(df, symbol)