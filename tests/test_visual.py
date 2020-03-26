from apocarich.core import get_stock_prices
from apocarich.visual import visualize_data_frame


def test_visualize_data_frame():
    df = get_stock_prices("BMW")
    visualize_data_frame(df)