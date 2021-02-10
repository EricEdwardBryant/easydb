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
    db <- DBI::dbConnect(RSQLite::SQLite(), cnf$db)

    for (name in names(cnf$keys)) {
      message('Checking keys for ', name, ' table... ', appendLF = F)

      key_cols <- cnf$keys[[name]]

      tbl <-
        tbl(db, name) %>%
        select( {{ key_cols }} ) %>%
        collect()

      dups <- duplicated(tbl) | duplicated(tbl, fromLast = TRUE)

      if (any(dups)) {
        message('Duplicated keys:')
        tbl %>%
          mutate(row = 1:n()) %>%
          filter({{ dups }}) %>%
          arrange( !!! syms({{ vars }}) ) %>%
          as.data.frame() %>%
          print()
      } else {
        message('OK')
      }
    }
  }
}
