from apocarich.utils import is_weekend


def test_is_weekend():
    assert not is_weekend("2020-01-01")
    assert not is_weekend("2020-01-02")
    assert not is_weekend("2020-01-03")
    assert is_weekend("2020-01-04")
    assert is_weekend("2020-01-05")
    assert not is_weekend("2020-01-06")
    assert not is_weekend("2020-01-07")
