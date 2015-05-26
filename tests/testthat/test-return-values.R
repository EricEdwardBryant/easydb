context('Test return values')

test_that('Return values match expected format', {
  cnf <- db_update(system.file('db/cnf.yaml', package = 'easydb'))
  expect_match(cnf, '\\.yaml')

  src <- db_build(system.file('db/cnf.yaml', package = 'easydb'))
  expect_true(is.src(src))

  dump <- db_dump(src, system.file('db', package = 'easydb'))
  expect_identical(basename(dump), c("cars.csv", "organisms.csv", "systems.csv"))
})