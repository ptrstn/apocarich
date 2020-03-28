import datetime
from pathlib import Path

from apocarich.data import remove_all_may_be_incomplete_files
from apocarich.settings import DATE_FORMAT
from apocarich.utils import is_weekend, create_empty_file, is_today


def test_is_weekend():
    assert not is_weekend("2020-01-01")
    assert not is_weekend("2020-01-02")
    assert not is_weekend("2020-01-03")
    assert is_weekend("2020-01-04")
    assert is_weekend("2020-01-05")
    assert not is_weekend("2020-01-06")
    assert not is_weekend("2020-01-07")


def test_is_today():
    today = datetime.date.today().strftime(DATE_FORMAT)
    assert not is_today("2001-09-11")
    assert is_today(today)


def test_create_empty_file():
    file_path = Path("test_data/a/long/walk/to/freedom/MAY_BE_INCOMPLETE")
    assert not file_path.exists()
    create_empty_file(file_path)
    assert file_path.exists()
    file_path.unlink()
    assert not file_path.exists()


def test_remove_all_may_be_incomplete_files():
    file_path_1 = Path("test_data/bla/MAY_BE_INCOMPLETE")
    file_path_2 = Path("test_data/blubb/MAY_BE_INCOMPLETE")
    assert not file_path_1.exists()
    assert not file_path_2.exists()
    create_empty_file(file_path_1)
    create_empty_file(file_path_2)
    assert file_path_1.exists()
    assert file_path_2.exists()
    remove_all_may_be_incomplete_files(base_path="test_data")
    assert not file_path_1.exists()
    assert not file_path_2.exists()
