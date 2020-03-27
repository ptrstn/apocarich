# apocarich

An apocalyptic stock market analyzer. 

## Install instructions

```bash
git clone https://github.com/ptrstn/apocarich
cd apocarich
python -m venv venv
. venv/bin/activate
pip install -e .
```

### R

Plots are created using the R language. 

Under arch linux you can install it with:

```bash
sudo pacman -S r
```

If you use a different operating system, then check [this link](https://www.r-project.org/about.html). 

### Amazon aws-cli

You also need aws-cli to retrieve the data from Xetra.
At Arch linux you can install it with:

```bash
sudo pacman -S aws-cli
```

If you use a different operating system, then check [this link](https://docs.aws.amazon.com/de_de/cli/latest/userguide/cli-chap-install.html). 

## Usage

### Help

```bash
apocarich --help
```

Output:

```bash
usage: apocarich [-h] [--version] [--retrieve-data] [--start DATE] [--end DATE] [--update-csv]

Analyzing the stock market

optional arguments:
  -h, --help       show this help message and exit
  --version        show program's version number and exit

Retrieving data from Xetra:
  --retrieve-data  Retrieve data from Xetra using the Amazon aws-cli
  --start DATE     Start date (default is 2019-11-01)
  --end DATE       End date (default is today)

Updating exported data.csv by retrieved data:
  --update-csv     Generates an updated data.csv by regrouping previously retrieved data
```

### Retrieve Data

First you have to retrieve some data. The following command downloads data from Xetra using the Amazon aws-cli.

```bash
apocarich --retrieve-data
```

If you want to specify specific dates, then you can use the ```--start``` and ```--end``` arguments:


```bash
apocarich --retrieve-data --start 2020-01-01 --end 2020-03-26
```

### Process data

For the next step you have to regroup the raw data, to be able to visualize them later.

Create the grouped CSV file, based on previously retrieved data:

```bash
apocarich --update-csv
```

### Create plots

Once the data is processed you can run the R script that generates a plot for you.
You can specify different arguments to further filter your data.

| argument            | Description                                                                  |
|---------------------|------------------------------------------------------------------------------|
| ```--start```       | Start Date                                                                   |
| ```--end```         | End Date                                                                     |
| ```--apocalypse```  | Date of when shit the fan.                                                   |
| ```--stocktype```   | "Common stock", "ETF", "ETC", "ETN" or "Other"                               |
| ```--numstocks```   | Number of stocks to visualize at once.                                       |
| ```--windowsize```  | Moving average window size                                                   |
| ```--numchars```    | Number of characters to display per subtitle                                 |
| ```--outdir```      | Path of the output directory                                                 |
| ```--untilrecent``` | Calculate loss by biggest drop after apocalypse day or until most recent day |

Run the R script:

```bash
 Rscript R/run.R 
```

You can also specify the arguments described above as follows:

```bash
 Rscript R/run.R --start 2020-02-01 --end 2020-03-26 --apocalypse 2020-02-15 --numchars 5 --outdir images --windowsize 10 --stocktype ETF
```
