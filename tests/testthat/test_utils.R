library(lgpr)

# -------------------------------------------------------------------------

context("General utility functions")

test_that("ensure_len works correctly", {
  reason <- "length of <a> was expected to be 1 or 5, but found length 3"
  a <- c(1, 2, 3)
  expect_error(ensure_len(a, 5), reason)
  expect_equal(ensure_len(a, 3), a)
  expect_equal(ensure_len(4.2, 3), c(4.2, 4.2, 4.2))
})

test_that("dollar errors correctly", {
  a <- list(moi = c(2, 3, 4), juu = 1)
  reason <- "'joo' not found in <a>! Found:"
  expect_error(dollar(a, "joo"), reason)
})

test_that("common array utilities work correctly", {
  a <- matrix(c(1, 2, 3, 10, 20, 30), 2, 3, byrow = TRUE)
  expect_equal(row_vars(a), c(1.0, 100.0))
  expect_equal(rowSums(normalize_rows(a)), c(1.0, 1.0))
  rownames(a) <- c("jaa", "hei")
  expect_equal(select_row(a, "hei"), c(10, 20, 30))
  reason <- "must be a multiple of <L>"
  expect_error(array_to_arraylist(a, 2), reason)
  x <- repvec(c(1, 2, 3), 4)
  expect_equal(reduce_rows(x), c(1, 2, 3))
})

test_that("squeeze_second_dim works correctly", {
  a <- matrix(c(1, 2, 3, 10, 20, 30), 2, 3, byrow = TRUE)
  expect_error(squeeze_second_dim(a), "dimensions in <x> must be 3")
  b <- array(a, dim = c(2, 0, 3))
  expect_error(squeeze_second_dim(b), "2nd dimension of <x> must be")
  a <- array(0, dim = c(4, 2, 3))
  a[, 2, ] <- a[, 2, ] + 1
  b <- squeeze_second_dim(a)
  expect_equal(dim(b), c(8, 3))
  a <- array(0, dim = c(4, 1, 3))
  b <- squeeze_second_dim(a)
  expect_equal(dim(b), c(4, 3))
  a <- array(0, dim = c(4, 1, 1))
  b <- squeeze_second_dim(a)
  expect_equal(dim(b), c(4, 1))
})


test_that("add_to_columns works correctly", {
  x <- array(0, c(3, 2))
  a <- add_to_columns(x, c(1.1, 1.2, 1.3))
  expect_equal(dim(a), c(3, 2))
  reason <- "has length 1, but its length should be 3"
  expect_error(add_to_columns(x, 1.2), reason)
})


test_that("link_inv functions are inverses of the link functions", {
  x <- c(1.2, -1, 0, 2)
  for (likelihood in likelihood_list()) {
    y <- link_inv(x, likelihood)
    expect_equal(x, link(y, !!likelihood))
  }
})

test_that("validate_dimension_list works correctly", {
  x <- list(c(3, 2), c(3, 2), c(3, 2))
  expect_null(validate_dimension_list(x))
  x <- list(c(11, 2), c(3, 9), c(3, 2))
  expect_equal(length(validate_dimension_list(x)), 3)
})

test_that("validate_lengths works correctly", {
  a <- c(100, 200)
  b <- c(9, 9, 9, 9)
  expect_equal(validate_lengths(a, b), "lengths do not agree!")
  expect_null(validate_lengths(a, a))
})

test_that("map_factor_to_caseid works correctly", {
  x_fac <- as.factor(c("F", "F", "F", "M", "M", "M"))
  x_cont_mask <- c(1, 1, 1, 1, 0, 0)
  reason <- "inconsistent x_cont_mask values for x_fac = M"
  expect_error(map_factor_to_caseid(x_fac, x_cont_mask, "joo"), reason)
})

test_that("large_data_msg works correctly", {
  expect_output(large_data_msg(1000, 300))
})

test_that("get_num_ns works correctly", {
  pr <- list(wrp = igam(14, 5))
  m <- create_model(y ~ gp(age) + zs(id), testdata_001)
  expect_equal(get_num_ns(get_stan_input(m)), 0)
  m <- create_model(y ~ gp_vm(age) + zs(id), testdata_001, prior = pr)
  expect_equal(get_num_ns(get_stan_input(m)), 1)
  m <- create_model(y ~ gp_vm(age) + gp_ns(blood) + zs(id), testdata_001,
    prior = pr
  )
  expect_equal(get_num_ns(get_stan_input(m)), 2)
})
