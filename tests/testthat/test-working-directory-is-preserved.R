context('Is working directory preserved?')

test_that('Working directory is preserved', {

  example <- system.file('db/cnf.yaml', package = 'easydb')
  wd <- getwd()

  # Check after updating source
  db_update(example)
  expect_equal(wd, getwd())

  # Check after building db
  db_build(example)
  expect_equal(wd, getwd())

})