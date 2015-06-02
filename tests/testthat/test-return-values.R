context('Test return values')

test_that('Return values match expected format', {
  cnf <- db_update(system.file('db/cnf.yaml', package = 'easydb'))
  expect_true(inherits(cnf, 'dbcnf'))

  cnf <- db_build(system.file('db/cnf.yaml', package = 'easydb'))
  expect_true(inherits(cnf, 'dbcnf'))

  cnf <- db_dump(cnf, system.file('db', package = 'easydb'))
  expect_true(inherits(cnf, 'dbcnf'))

  cnf <- db_config(system.file('db/cnf.yaml', package = 'easydb'))
  expect_true(inherits(cnf, 'dbcnf'))
})