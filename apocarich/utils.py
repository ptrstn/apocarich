import datetime

from apocarich.settings import DATE_FORMAT


def is_weekend(date_string):
    date = datetime.datetime.strptime(date_string, DATE_FORMAT)
    return date.weekday() >= 5


def is_today(date_string):
    return datetime.datetime.now().strftime(DATE_FORMAT) == date_string


def create_empty_file(path):
    with open(path, "w"):
        pass
