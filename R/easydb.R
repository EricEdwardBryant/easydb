#' @import dplyr yaml assertthat
NULL

#' Read an EasyDB configuration file
#'
#' Reads an EasyDB configuration file and returns a 'dbcnf' object.
#'
#' @param cnf Path to an EasyDB configuration file, or the result of
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

#--db_build--------------------------------------------------------------------
#' Build a database given a configuration file
#'
#' Builds an SQLite database given an EasyDB configuration file.
#'
#' @param cnf Path to an EasyDB configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_build <- function(cnf) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)

  # DB is written relative to cnf
  old <- setwd(cnf$dir)
  src <- src_sqlite(cnf$name, create = TRUE)

  for (tbl_name in names(cnf$table)) {
    db_import_table(cnf$table[[tbl_name]], tbl_name, src, overwrite = TRUE)
  }
  on.exit(setwd(old))
  return(invisible(cnf))
}


#--db_update------------------------------------------------------------
#' Run database update expressions
#'
#' Updates plain text source tables by evaluating R expressions in an easydb
#' configuration file.
#'
#' @param cnf Path to an EasyDB configuration file, or the result of
#' \link{db_config}.
#'
#' @export

db_update <- function(cnf) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)

  # Update expressions are executed in the directory of cnf
  old <- setwd(cnf$dir)

  if (is.null(cnf$update)) {
    warning('No "update:" field in configuration file: ', cnf)
  } else if (!is.list(cnf$update)) {
    warning('"update:" field should be a list of "name: expression" pairs. ',
            'No updates were performed.')
  } else {
    for (name in names(cnf$update)) eval(parse(text = cnf$update[[name]]))
  }
  on.exit(setwd(old))
  return(invisible(cnf))
}


#--db_dump---------------------------------------------------------------------
#' Dump an SQLite database to CSVs
#'
#' Dumps each table in an SQLite database to CSVs
#'
#' @param cnf Path to an EasyDB configuration file, or the result of
#' \link{db_config}.
#' @param dir Directory to write CSVs.
#'
#' @export

db_dump <- function(cnf, dir) {
  if (!inherits(cnf, 'dbcnf')) cnf <- db_config(cnf)
  src <- src_sqlite(cnf$db)

  assert_that(is.src(src), is.dir(dir))
  tbl_names <- db_list_tables(src$con)

  for (tbl_name in tbl_names) {
    src %>% tbl(tbl_name) %>% collect %>%
      write.csv(paste0(dir, '/', tbl_name, '.csv'), row.names = FALSE)
  }

  return(invisible(cnf))
}

