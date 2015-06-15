# Easy Databases with *R*

This *R* package is designed to streamline import and export to/from SQLite
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
## All paths are relative to this configuration file
name: example.sqlite

update:  # update_name: R expression
  cars: write.csv(cars, 'cars.csv', row.names = FALSE)
  organisms: source('organisms.R')

table:   # table_name: path/to/table.csv
  organisms: organisms.csv
  cars: cars.csv
  systems: systems.csv

keys:    # table_name: field1, field2, field3
  organisms: ncbi_taxonomy_id

test:    # test_name: R expression
  fields_exist: source('check-fields.R')
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

## Doctor

Keys and tests can be specified in your configuration file. The function 
`db_doctor` will run all tests, and check that specified keys are unique.

```r
db_doctor('path/to/config.yaml')
```

```
## Checking keys for systems table... Duplicated keys:
##         system_id row
## 1 BIOGRID:0000067  29
## 2 BIOGRID:0000067  30
## Checking keys for organisms table... OK
```

## Dump

Sometimes we want to extract tables from a database. The function `db_dump` 
will do just that.

```r
db_dump('path/to/config.yaml', 'path/to/dump')
```

# A silly example

All `db_*` functions accept either a path to an EasyDB configuration file, or
a `dbcnf` object as their first argument, and they all return a `dbcnf` object,
which allows `db_*` functions to be chained together in a pipeline. The 
following silly example takes a path to a database configuration file, updates 
source tables, builds a database, then writes those tables from the database to
CSVs on your desktop - it's the circle of life!

```r
library(easydb)

'path/to/config.yaml' %>%
  db_update %>%
  db_build %>%
  db_dump('~/Desktop')
```
