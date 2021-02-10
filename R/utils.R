# Used to set S3 class of object in pipeline
set_class <- function(obj, ...) { class(obj) <- c(...); return(obj) }

add_to_list <- function(list, ...) c(list, list(...))

#-- db_write_table ------------------------------------------------------------
# Write a table to a database
#
# Coerces tbl objects to 'data.frame'
#
# @param tbl Any object that inherits the 'data.frame' class.
# @param tbl_name The name of the table.
# @param con A DBI connection.
# @param overwrite Flag. Whether to overwrite an existing table.
# @param append Flag. Whether to append to an existing table.
#
#' @importFrom DBI dbWriteTable

db_write_table <- function(tbl,
                           tbl_name,
                           con,
                           overwrite = !append,
                           append = !overwrite) {
  assert_that(
    is.string(tbl_name),
    DBI::dbIsValid(con),
    is.flag(overwrite),
    is.flag(append),
    inherits(tbl, 'data.frame')
  )

  class(tbl) <- 'data.frame'

  dbWriteTable(
    con,
    tbl_name,
    tbl,
    overwrite = overwrite,
    append = append,
    row.names = FALSE
  )
}

#-- db_import_table -----------------------------------------------------------
# Import a table from text file to database.
#
# Reads a plain text table and writes it to a database. Future versions will
# automate chuncked reads for very large tables. Currently uses
# \link[data.table]{fread} for quickly reading plain text tables.
#
# @param tbl_paths Character. The path or paths to the table.
# @param tbl_name String. The name of the table.
# @param con A DBI connection.
# @param overwrite Flag. Should an existing table be overwritten? Defaults to
# \code{!append}
# @param append Flag. Should an existing table be append? Defaults to
# \code{!overwrite}.
# @param ... Further arguments passed to \link[data.table]{fread}.
#
#' @importFrom data.table fread
#' @importFrom magrittr extract

db_import_table <- function(tbl_paths,
                            tbl_name,
                            con,
                            overwrite = !append,
                            append = !overwrite,
                            ...) {
  assert_that(
    DBI::dbIsValid(con),
    is.string(tbl_name),
    is.flag(overwrite),
    is.flag(append),
    length(tbl_paths) > 0
  )

  # Multiple table paths will be individually read/written to the database
  # If a directory is provided then all files within this directory will be
  # treated as if they are chunks of the same table
  paths <- lapply(tbl_paths, function(p) {
    if (!is.null(names(p))) {
      # If names are specified then assume they are arguments to list.files
      if (is.null(p$full.names)) p$full.names <- TRUE  # full names by default
      if (is.null(p$recursive))  p$recursive  <- TRUE  # recursive by default
      files <- do.call(list.files, p)
      files <- files[!sapply(files, is.dir)]           # remove directories
    } else if (is.dir(p)) {
      files <- list.files(p, full.names = TRUE)
      files <- files[!sapply(files, is.dir)]           # remove directories
    } else {
      files <- p
    }
    return(files)
  })

  # Will set to FALSE once first table is written
  paths <- unlist(paths)
  if (length(paths) == 0) stop('No files found for table: ', tbl_name, call. = FALSE, '\nQuery: ', tbl_paths)

  lapply(1:length(paths), function(i) {

    # Read / write table
    fread(paths[i], data.table = FALSE, ...) %>%
      db_write_table(tbl_name, con, overwrite = if (i == 1) overwrite else FALSE)
  })

  return(invisible())
}
