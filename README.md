# apocarich

An apocalyptic stock market analyzer. 

## Install instructions

```bash
pip install --user git+https://github.com/ptrstn/apocarich
```

## Usage

Export your API key:

```bash
export ALPHAVANTAGE_API_KEY="<YOUR API KEY>"
```

Run the script:

```bash
apocarich
```

## Get Data

```bash
yay -S aws-cli

date='2020-03-20'
date='2017-05-27' # min von eurex
date='2017-06-17' # min von xetra 

aws s3 sync s3://deutsche-boerse-xetra-pds/${date} data/deutsche-boerse-xetra-pds/${date} --no-sign-request
aws s3 sync s3://deutsche-boerse-eurex-pds/${date} data/deutsche-boerse-eurex-pds/${date} --no-sign-request

date='2017-06-18' 
aws s3 sync s3://deutsche-boerse-xetra-pds/${date} data/deutsche-boerse-xetra-pds/${date} --no-sign-request
aws s3 sync s3://deutsche-boerse-eurex-pds/${date} data/deutsche-boerse-eurex-pds/${date} --no-sign-request

date='2017-06-19' 
aws s3 sync s3://deutsche-boerse-xetra-pds/${date} data/deutsche-boerse-xetra-pds/${date} --no-sign-request
aws s3 sync s3://deutsche-boerse-eurex-pds/${date} data/deutsche-boerse-eurex-pds/${date} --no-sign-request

ls data/deutsche-boerse-xetra-pds/${date}
```

Columns:

```
['ISIN',
 'Mnemonic',
 'SecurityDesc',
 'SecurityType',
 'Currency',
 'SecurityID',
 'Date',
 'Time',
 'StartPrice',
 'MaxPrice',
 'MinPrice',
 'EndPrice',
 'TradedVolume',
 'NumberOfTrades',
 'Price']
```

## Links

- https://registry.opendata.aws/deutsche-boerse-pds/
- https://github.com/Deutsche-Boerse/dbg-pds

- https://quant.stackexchange.com/questions/38429/symbols-for-dax-from-alpha-vantage
- https://www.alphavantage.co/documentation/

- https://github.com/Originate/dbg-pds-tensorflow-demo/blob/master/notebooks/01-data-cleaning-single-stock.ipynb
- https://registry.opendata.aws/
- https://towardsdatascience.com/python-stock-analysis-candlestick-chart-with-python-and-plotly-e619143642bb

- https://towardsdatascience.com/implementing-moving-averages-in-python-1ad28e636f9d
- https://janakiev.com/blog/python-shell-commands/
- https://stackoverflow.com/questions/19587118/iterating-through-directories-with-python
- https://stackoverflow.com/questions/29384696/how-to-find-current-day-is-weekday-or-weekends-in-python

- https://www.youtube.com/watch?v=qy0fDqoMJx8

### Stock APIs

- https://dataondemand.nasdaq.com/docs/
