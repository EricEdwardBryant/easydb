# Easy Databases with *R*

This *R* package makes it easy to setup a SQLite database using plain text 
tables. With this package you can:

- Create a SQLite database from one simple configuration file.
- Work with large tables that do not fit into active memory.
- Easily update data from remote sources.
- Write and run tests on your database.
- Detect duplicate keys.
- Dump tables in a SQLite database to CSVs.
- (TODO) specify expected *R* data types and automatically convert when querying the database.

**Note:** Files are imported into the database one at a time using 
`data.table::fread`. Very large tables that do not fit into memory can and 
should be split into separate source files before building the database.

# Installation

This package is not available on CRAN, but you can easily install it using
[devtools](https://github.com/hadley/devtools).

```r
if (!require(devtools)) install.packages('devtools')
devtools::install_github('ericedwardbryant/easydb')
```

# Setup

To build a database, all you need to do is create an easydb configuration file.
This file is written in [YAML](http://www.yaml.org/spec/1.2/spec.html) (the 
same syntax used in the metadata section of [Rmarkdown](http://rmarkdown.rstudio.com) 
documents). Below is an example configuration file.

```yaml
## All paths are relative to this configuration file
name: example.sqlite

update:  # update_name: R expression
  cars: write.csv(cars, 'cars.csv', row.names = FALSE)
  organisms: source('organisms.R')

table:   # table_name: path/to/table.csv
  cars: cars.csv
  systems: systems.csv
  # Multiple paths are supported for a single table.
  organisms:
    # Paths can be specified for a single file
    - organisms1.csv
    # Or as a directory of files
    - organisms
    # Or as named arguments to ?list.files
    - path: organisms
      pattern: organisms.\.csv
      ignore.case: yes
    # E.g. match all CSV files in same directory as this configuration file
    - pattern: \.csv$
      recursive: no

keys:    # table_name: field1, field2, field3
  organisms: ncbi_taxonomy_id

test:    # test_name: R expression
  fields_exist: source('check-fields.R')
```

Currently valid fields include:

- **name** - a file path for the SQLite database.
- **update** - a list of `name: value` pairs that specify an update name and an 
               *R* expression. These expressions are executed in order by 
               `db_update`.
- **table** - a list of `name: value` pairs that specify a table name and a 
              path to a table (tables are read by `data.table::fread`). If the 
              path is a directory, the tables in this directory will be 
              combined into a single table. Multiple paths will be imported 
              one at a time, allowing generation of very large tables that
              can be queried on disk via `dplyr` and/or `RSQLite`.
- **keys** - a list of `name: value` pairs that specify a table name and an 
             array of fields to be used as keys.
- **test** - a list of `name: value` pairs that specify a test name and an *R* 
             expression. These expressions are executed in order by `db_doctor`.

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
Every entry under `update:` will be parsed and evaluated as an *R* expression. 

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

All `db_*` functions accept either a path to an easydb configuration file, or
a `dbcnf` object as their first argument, and they all return a `dbcnf` object,
which allows `db_*` functions to be chained together in a pipeline. The 
following silly example takes a path to a database configuration file, updates 
source tables, builds a database, then writes those tables from the database to
CSVs on your desktop, and finally connects to the database as a 
[dplyr src](http://cran.r-project.org/web/packages/dplyr/vignettes/databases.html).

```r
library(easydb)

src <- 
  'path/to/config.yaml' %>%
  db_config %>%             # reads the configuration file
  db_update %>%             # runs updates
  db_build %>%              # imports tables
  db_doctor %>%             # runs tests and checks keys
  db_dump('~/Desktop') %>%  # writes tables to Desktop
  src_easydb()              # connects to db as dplyr src
```
