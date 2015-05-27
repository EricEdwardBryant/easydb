# Easy Databases with *R*

This is an *R* package designed to streamline import and export to/from SQLite
databases. With this package you can:

- Create a SQLite database from one simple configuration file.
- Update your data from remote sources with a single command.
- Dump tables in a database to CSVs.
- TODO: Specify keys.
- TODO: Visualize a database schema.

# Motivation

I like to store data in plain text so I can easily version it with Git.
But, this all starts to become a mess as my collection of tables grows.
Databases and RData files would work nicely, but they don't play so well with
Git. So, this package makes it easy to generate a database from plain-text 
tables.

# Getting Started

This package is not yet available on CRAN, but you can easily install it using
[devtools](https://github.com/hadley/devtools).

```r
if (!require(devtools)) install.packages('devtools')
devtools::install_github('ericedwardbryant/easydb')
library(easydb)
```

To build a database, all you need to do is create an easydb configuration file.
This file is written in [YAML](http://www.yaml.org/spec/1.2/spec.html) (if you've written any
[Rmarkdown](http://rmarkdown.rstudio.com) documents then you know how to write
a little YAML). Below is an example configuration file.

```yaml
## Update scripts and table paths are relative to this configuration file
name: example  

update:  # table_name: R expression
  cars: write.csv(cars, 'cars.csv', row.names = FALSE)
  organisms: source('organisms.R')

table:   # table_name: path/to/table.csv
  organisms: organisms.csv
  cars: cars.csv
  systems: systems.csv

keys:    # table_name: field1, field2, field3
  organisms: ncbi_taxonomy_id
```

## Build

Once you have created your configuration file, you can build your database in
a single command with `db_build`. This function reads each table and writes it
to the database. Any file that can be read with the default settings of 
`data.table::fread` can be added to the database.

```r
db_build('path/to/config.yaml')
```

## Update

Often times data in a table will need to be updated from a remote source. 
The function `db_update` provides a means for updating your plain-text tables. 
Every configuration entry under `update:` will be parsed and evaluated as an 
*R* expression. 

```r
db_update('path/to/config.yaml')
```

## Dump

Sometimes we want to extract tables from a database. The function `db_dump` 
will to just that given a [dplyr](https://github.com/hadley/dplyr) `src`.

```r
library(dplyr)
src_sqlite('path/to/example.sqlite') %>% db_dump('path/to/dump')
```

# A silly example

`db_update` returns `path/to/config.yaml` so you can easily pipe to
`db_build` after updating. And since `db_build` returns a `src` connection, you
can immediately begin querying your new database. The following silly example
takes a path to a database configuration file, updates source tables, builds a
database, then writes those tables from the database to CSVs on your desktop -
it's the circle of life.

```r
library(easydb)

'path/to/config.yaml' %>%
  db_update %>%
  db_build %>%
  db_dump('~/Desktop')
```
