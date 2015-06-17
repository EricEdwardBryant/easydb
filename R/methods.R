#-- cnf print method ----------------------------------------------------------
#' @export

print.dbcnf <- function(x, what = c('cnf', 'db', 'dir', 'name', 'table',
                                    'update', 'keys')) {
  cat(as.yaml(x[what]))
}

