library(lgpr)

# -------------------------------------------------------------------------

context("Posterior sampling and optimization")

my_prior <- list(
  alpha = normal(1, 0.1),
  ell = normal(1, 0.1),
  sigma = normal(1, 0.1)
)

dat <- testdata_001
model <- create_model(y ~ gp(age), dat, prior = my_prior)

test_that("sample_model can do posterior sampling", {
  fit <- sample_model(
    model = model,
    iter = 1200,
    chains = 1,
    refresh = 0,
    seed = 123
  )

  expect_s4_class(fit, "lgpfit")
  p1 <- plot_draws(fit)
  p2 <- plot_draws(fit, type = "trace")
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
  expect_error(get_y_rng(fit), "f was not sampled")
  expect_error(plot_warp(fit), "the model does not have warping parameters")
  expect_error(plot_beta(fit), "there are no heterogeneous effects")
})

test_that("optimize_model can optimize MAP parameters", {
  fit <- optimize_model(model, iter = 10, seed = 123)
  expect_equal(class(fit), "list")
})


# -------------------------------------------------------------------------

context("Posterior sampling of f with different obs models")

test_that("f can be sampled with gaussian likelihood", {
  dat <- testdata_001
  suppressWarnings({
    fit <- lgp(
      formula = y ~ gp(age) + categ(sex),
      sample_f = TRUE,
      data = dat,
      iter = 200,
      chains = 1,
      refresh = 0,
    )
    expect_s4_class(fit, "lgpfit")
    expect_equal(get_stan_input(fit)$is_f_sampled, 1)
  })
})

test_that("f can be sampled with poisson likelihood", {
  dat <- testdata_001
  dat$y <- round(exp(dat$y))
  suppressWarnings({
    fit <- lgp(
      formula = y ~ gp(age) + categ(sex) * gp(age),
      likelihood = "poisson",
      data = dat,
      iter = 200,
      chains = 1,
      refresh = 0,
    )
    expect_s4_class(fit, "lgpfit")
  })
})

test_that("f can be sampled with nb likelihood", {
  dat <- testdata_001
  dat$y <- round(exp(dat$y))
  suppressWarnings({
    fit <- lgp(
      formula = y ~ gp(age) + categ(sex) * gp(age),
      likelihood = "nb",
      data = dat,
      iter = 200,
      chains = 1,
      refresh = 0,
    )
    expect_s4_class(fit, "lgpfit")
    p1 <- plot_draws(fit)
    p2 <- plot_draws(fit, regex_pars = "f_latent")
    expect_s3_class(p1, "ggplot")
    expect_s3_class(p2, "ggplot")
  })
})

test_that("f can be sampled with binomial likelihood", {
  dat <- testdata_001
  dat$y <- round(exp(dat$y))
  suppressWarnings({
    fit <- lgp(
      formula = y ~ gp(age) + zs(sex) * gp(age),
      likelihood = "binomial",
      data = dat,
      iter = 200,
      chains = 1,
      refresh = 0,
      num_trials = 10
    )
    expect_s4_class(fit, "lgpfit")
  })
})

test_that("f can be sampled with beta-binomial likelihood", {
  dat <- testdata_001
  dat$y <- round(exp(dat$y))
  suppressWarnings({
    fit <- lgp(
      formula = y ~ gp(age) + zs(sex) * gp(age),
      likelihood = "bb",
      data = dat,
      iter = 200,
      chains = 1,
      refresh = 0,
      num_trials = 10
    )
  })
  expect_s4_class(fit, "lgpfit")
  expect_output(show(fit@model))
  r <- relevances(fit)
  expect_equal(length(r), 3)
  s <- select(fit)
  expect_equal(length(s$Component), 3)
  t <- seq(0, 40, by = 1)
  x_pred <- new_x(dat, t)
  p <- pred(fit, x_pred, reduce = NULL, draws = c(1:3), verbose = FALSE)
  plt1 <- plot_pred(fit, x_pred, p) # [0,1] scale
  plt2 <- plot_f(fit, x_pred, p)
  expect_s3_class(plt1, "ggplot")
  expect_s3_class(plt2, "ggplot")
})

test_that("verbose mode can be used", {
  dat <- testdata_001
  expect_output(
    suppressWarnings({
      lgp(
        formula = y ~ gp(age) + zs(sex) * gp(age),
        data = dat,
        iter = 20,
        chains = 1,
      )
    })
  )
})