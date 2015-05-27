#--db_build--------------------------------------------------------------------
#' Build a database given a configuration file
#'
#' Builds an SQLite database given an easydb configuration file
#'
#' @param cnf String. A path to easydb configuration file.
#'
#' @export
#' @importFrom assertthat is.string is.dir assert_that
#' @importFrom dplyr src_sqlite bind_rows
#' @importFrom yaml yaml.load_file

db_build <- function(cnf) {
  assert_that(is.string(cnf), file.exists(cnf))
  dir    <- dirname(cnf)
  config <- yaml.load_file(cnf)
  tbls   <- config$table

  # DB is written relative to cnf
  old <- setwd(dirname(cnf))
  src <- src_sqlite(config$name, create = TRUE)

  for (tbl in names(tbls)) {
    tbl_path <- tbls[[tbl]]
    if (is.dir(tbl_path)) {
      tbl_path %>%
        list.files(full.names = TRUE) %>%
        lapply(fread) %>%
        bind_rows %>%
        db_write_table(tbl, src, overwrite = TRUE)
    } else {
      db_add_table(tbl, tbl_path, src, overwrite = TRUE)
    }
  }
  on.exit(setwd(old))
  return(src)
}


#--db_add_table----------------------------------------------------------------
#' Add a table and write to a database.
#'
#' Reads a plain text table and writes it to a database. Future versions will
#' automate chuncked reads for very large tables. Currently uses
#' \link[data.table]{fread} for quickly reading plain text tables.
#'
#' @param tbl_name String. The name of the table.
#' @param tbl_path String. The path to the table.
#' @param src A database source.
#' @param overwrite Flag. Should an existing table be overwritten? Defaults to
#' \code{!append}
#' @param append Flag. Should an existing table be append? Defaults to
#' \code{!overwrite}.
#' @param ... Further arguments passed to \link[data.table]{fread}.
#'
#' @export
#' @importFrom dplyr is.src %>%
#' @importFrom data.table fread
#' @importFrom assertthat assert_that is.string

db_add_table <- function(tbl_name, tbl_path, src, overwrite = !append,
                         append = !overwrite, ...) {
  assert_that(
    is.src(src), is.string(tbl_name), is.string(tbl_path), is.flag(overwrite),
    is.flag(append)
  )
  tbl_path %>%
    fread(...) %>%
    db_write_table(tbl_name, src, overwrite = overwrite, append = append)
}


#--db_update------------------------------------------------------------
#' Run database update expressions
#'
#' Updates plain text source tables by evaluating R expressions in an easydb
#' configuration file.
#'
#' @param cnf String. A path to easydb configuration file.
#'
#' @export
#' @importFrom yaml yaml.load_file

db_update <- function(cnf) {
  assert_that(is.string(cnf))
  upd <- yaml.load_file(cnf)$update

  # Update expressions are executed in the directory of cnf
  old <- setwd(dirname(cnf))

  for (name in names(upd)) eval(parse(text = upd[[name]]))
  on.exit(setwd(old))
  return(invisible(cnf))
}


#--db_dump---------------------------------------------------------------------
#' Dump an SQLite database to CSVs
#'
#' Dumps each table in an SQLite database to CSVs
#'
#' @param src A database source.
#' @param dir String. Directory to write CSVs.
#'
#' @export
#' @importFrom dplyr %>% db_list_tables tbl collect is.src
#' @importFrom assertthat is.string

db_dump <- function(src, dir) {
  assert_that(is.src(src), is.string(dir))

  tbl_names <- db_list_tables(src$con)

  for (tbl_name in tbl_names) {
    src %>% tbl(tbl_name) %>% collect %>%
      write.csv(paste0(dir, '/', tbl_name, '.csv'), row.names = FALSE)
  }

  return(invisible(paste0(dir, '/', tbl_names, '.csv')))
}

#--utils-----------------------------------------------------------------------

#' @importFrom assertthat assert_that is.string is.flag
#' @importFrom dplyr %>%
#' @importFrom DBI dbWriteTable

db_write_table <- function(tbl, tbl_name, src, overwrite = !append,
                           append = !overwrite) {
  assert_that(
    is.string(tbl_name), is.src(src), is.flag(overwrite), is.flag(append),
    tbl %>% inherits('data.frame')
  )
  class(tbl) <- 'data.frame'
  dbWriteTable(
    src$con, tbl_name, tbl, overwrite = overwrite, append = append,
    row.names = FALSE
  )
}
