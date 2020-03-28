from setuptools import setup, find_packages

setup(
    name="apocarich",
    version="0.0.1",
    url="https://github.com/ptrstn/apocarich",
    packages=find_packages(),
    install_requires=[
        "requests",
        "pandas",
        "awscli",
        "plotly",
        "matplotlib",
        "seaborn",
    ],
    entry_points={"console_scripts": ["apocarich=apocarich.__main__:main",]},
    scripts=["R/apocarich.R"],
)
