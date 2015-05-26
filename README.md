# Easy Database in R

This is an R package designed to streamline import and export to/from SQLite
databases. With this package you can:

- Create a SQLite database from one simple configuration file.
- Update your data from remote sources with a single command.
- Dump tables in a database to CSVs.
- TODO: Specify keys.
- TODO: Visualize a database schema.

# Motivation

I like to store data in plain text so I can easily version control it with Git.
But, this all starts to become a mess as my collection of tables grows.
Databases and RData files would work nicely, but they don't play so well with
Git. So, this package makes it easy to generate a database from version
controlled plain text tables.

# Getting Started

This package is not yet available on CRAN, but you can easily install it using
[devtools](https://github.com/hadley/devtools).

```r
if (!require(devtools)) install.packages('devtools')
devtools::install_github('ericedwardbryant/easydb')
```

To build a database from a directory of plain text tables, all you need to do
is add an easydb configuration file to this directory. This file is written in
[YAML](http://www.yaml.org/spec/1.2/spec.html), so if you've written any
[Rmarkdown](http://rmarkdown.rstudio.com) documents then you know how to write
a little YAML. Below is an example configuration file.

```yaml
## Scripts and paths should be written relative to this config file

# The name of your database
name: example

# Optional update scripts written as R expressions
update:
  cars: write.csv(cars, 'cars.csv', row.names = FALSE)
  organisms: source('organisms.R')

# Tables to include in the database (paths relative to config file)
table:
  organisms: organisms.csv
  cars: cars.csv
  systems: systems.csv

# TODO keys will be checked for uniqueness
keys:
  organisms: ncbi_taxonomy_id
```

Once you have created your configuration file, you can build your database in
a single command:

```r
easydb::db_build('path/to/config.yaml')
```

And you can update your tables in a single command:

```r
easydb::db_update_source('path/to/config.yaml')
```

`db_update_source` returns `path/to/config.yaml` so you can easily pipe to
`db_build` after updating. And since `db_build` returns a `src` connection, you
can immediately begin querying your new database. The following silly example
takes a path to a database configuration file, updates source tables, builds a
database, then writes those tables from the database to CSVs on your desktop -
it's the circle of life.

```r
library(easydb)

'path/to/config.yaml' %>%
  db_update_source %>%
  db_build %>%
  db_dump('~/Desktop')
```
