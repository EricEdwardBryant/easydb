#' @import dplyr yaml assertthat
NULL

#-- src_easydb ----------------------------------------------------------------
#' Connect to an easydb
#'
#' Connects to an easydb source, and builds the database if it has not been
#'
#' @export
src_easydb <- function(cnf, update = FALSE) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)
  if (update) { cnf %>% db_update %>% db_build }
  if (!file.exists(cnf$db)) db_build(cnf)
  DBI::dbConnect(RSQLite::SQLite(), cnf$db)
}

#-- db_config -----------------------------------------------------------------
#' Read an easydb configuration file
#'
#' Reads an easydb configuration file and returns a 'dbcnf' object.
#'
#' @param cnf Path to an easydb configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_config <- function(cnf) {
  if (inherits(cnf, 'dbcnf')) return(cnf)
  assert_that(is.string(cnf), file.exists(cnf))
  full_path <- normalizePath(cnf)
  full_path %>%
    yaml.load_file %>%
    add_to_list(
      cnf = full_path,
      dir = dirname(full_path),
      db  = paste(dirname(full_path), .$name, sep = '/')
    ) %>%
    set_class('dbcnf', class(.))
}

#-- db_build ------------------------------------------------------------------
#' Build an easydb
#'
#' Builds an SQLite database given an easydb configuration file.
#'
#' @param cnf Path to an easydb configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_build <- function(cnf) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)

  # DB is written relative to cnf
  old <- setwd(cnf$dir); on.exit(setwd(old))

  con <- DBI::dbConnect(RSQLite::SQLite(), cnf$name)
  message('Building ', cnf$name, ' at:\n', cnf$db)
  for (tbl_name in names(cnf$table)) {
    message('Importing ', tbl_name, ' ... ', appendLF = F)
    db_import_table(cnf$table[[tbl_name]], tbl_name, con, overwrite = TRUE)
    message('OK')
  }
  return(invisible(cnf))
}


#-- db_update -----------------------------------------------------------------
#' Run updates for an easydb
#'
#' Updates plain text source tables by evaluating R expressions in an easydb
#' configuration file.
#'
#' @param cnf Path to an easydb configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_update <- function(cnf) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)

  # Update expressions are executed in the directory of cnf
  old <- setwd(cnf$dir); on.exit(setwd(old))

  if (is.null(cnf$update)) {
    warning('No "update:" field in configuration file: ', cnf)
  } else if (!is.list(cnf$update)) {
    warning('"update:" field should be a list of "name: expression" pairs. ',
            'No updates were performed.')
  } else {
    for (name in names(cnf$update)) {
      message('Updating ', name, ' ... ', appendLF = F)
      eval(parse(text = cnf$update[[name]]))
      message('OK')
    }
  }
  return(invisible(cnf))
}


#-- db_dump -------------------------------------------------------------------
#' Dump an easydb database to CSVs
#'
#' Dumps each table in an SQLite database to CSVs
#'
#' @param cnf Path to an easydb configuration file, or the result of
#' \link{db_config}.
#' @param dir Directory to write CSVs.
#'
#' @export

db_dump <- function(cnf, dir) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)
  con <- DBI::dbConnect(RSQLite::SQLite(), cnf$db)

  assert_that(DBI::dbIsValid(con), is.dir(dir))

  tbl_names <- db_list_tables(con)

  for (tbl_name in tbl_names) {
    to <- paste0(dir, '/', tbl_name, '.csv')
    message('Writing ', to, ' ... ', appendLF = F)

    data.table::fwrite(collect(tbl(con, tbl_name)), to)

    message('OK')
  }
  return(invisible(cnf))
}


#-- db_doctor -----------------------------------------------------------------
#' Perform checkup on database
#'
#' Runs all tests and checks for duplicated keys.
#'
#' @param cnf Path to an easydb configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_doctor <- function(cnf) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)

  # Test expressions are executed in the directory of cnf
  old <- setwd(cnf$dir); on.exit(setwd(old))

  run_tests(cnf)
  check_keys(cnf)
  return(invisible(cnf))
}
