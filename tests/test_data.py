import datetime

from apocarich.data import retrieve_all_aws_data, update_data_csv, remove_all_may_be_incomplete_files
from apocarich.settings import DATE_FORMAT
from apocarich.utils import is_today, create_empty_file

base_path = "test_data"
start_date = "2020-02-14"
end_date = "2020-02-17"


def test_is_today():
    today = datetime.date.today().strftime(DATE_FORMAT)
    assert not is_today(start_date)
    assert is_today(today)


def test_create_empty_file():
    create_empty_file(f"{base_path}/MAY_BE_INCOMPLETE")


def test_retrieve_all_aws_data():
    today = datetime.date.today().strftime(DATE_FORMAT)
    retrieve_all_aws_data(start_date=start_date, end_date=end_date, base_path=base_path)
    retrieve_all_aws_data(start_date=today, end_date=today, base_path=base_path)


def test_update_data_csv():
    retrieve_all_aws_data(start_date=start_date, end_date=end_date, base_path=base_path)
    update_data_csv(base_path=base_path)


def test_remove_all_may_be_incomplete_files():
    remove_all_may_be_incomplete_files(base_path=base_path)