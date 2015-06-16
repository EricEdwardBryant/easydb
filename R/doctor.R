run_tests <- function(cnf) {
  if (!is.null(cnf$test)) {
    for (name in names(cnf$test)) {
      message('Testing ', name, ' ... ', appendLF = F)
      eval(parse(text = cnf$test[[name]]))
      message('OK')
    }
  }
}

check_keys <- function(cnf) {
  if (!is.null(cnf$keys)) {
    db <- src_sqlite(cnf$db)
    for (name in names(cnf$keys)) {
      message('Checking keys for ', name, ' table... ', appendLF = F)
      tbl  <- db %>% tbl(name) %>% select_(.dots = cnf$keys[[name]]) %>% collect
      dups <- duplicated(tbl) | duplicated(tbl, fromLast = TRUE)
      if (any(dups)) {
        message('Duplicated keys:')
        tbl %>%
          mutate(row = 1:n()) %>%
          filter_(~dups) %>%
          arrange_(.dots = cnf$keys[[name]]) %>%
          as.data.frame %>%
          print
      } else {
        message('OK')
      }
    }
  }
}
