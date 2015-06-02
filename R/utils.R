# Used to set S3 class of object in pipeline
set_class <- function(obj, ...) { class(obj) <- c(...); return(obj) }

add_to_list <- function(list, ...) c(list, list(...))

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

#--db_import_table----------------------------------------------------------------
# Import a table from text file to database.
#
# Reads a plain text table and writes it to a database. Future versions will
# automate chuncked reads for very large tables. Currently uses
# \link[data.table]{fread} for quickly reading plain text tables.
#
# @param tbl_path String. The path to the table.
# @param tbl_name String. The name of the table.
# @param src A database source.
# @param overwrite Flag. Should an existing table be overwritten? Defaults to
# \code{!append}
# @param append Flag. Should an existing table be append? Defaults to
# \code{!overwrite}.
# @param ... Further arguments passed to \link[data.table]{fread}.
#
#' @importFrom data.table fread
#' @importFrom magrittr extract

db_import_table <- function(tbl_path, tbl_name, src, overwrite = !append,
                            append = !overwrite, ...) {
  assert_that(
    is.src(src), is.string(tbl_name), is.string(tbl_path), is.flag(overwrite),
    is.flag(append)
  )
  if (is.dir(tbl_path)) {
    tbl_path %>%
      list.files(full.names = TRUE) %>%
      extract(!sapply(., is.dir)) %>%  # remove directories
      lapply(fread) %>%
      bind_rows %>%
      db_write_table(tbl_name, src, overwrite = overwrite, append = append)
  } else {
    tbl_path %>%
      fread(...) %>%
      db_write_table(tbl_name, src, overwrite = overwrite, append = append)
  }
}