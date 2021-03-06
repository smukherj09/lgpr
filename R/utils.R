#' Helper function for generic functions
#'
#' @description Helper function for generic functions that work on
#' both of \linkS4class{lgpmodel} and \linkS4class{lgpfit} class objects.
#' @param object an object of class \linkS4class{lgpmodel} or
#' \linkS4class{lgpfit}
#' @return an object of class \linkS4class{lgpmodel}
object_to_model <- function(object) {
  allowed <- c("lgpmodel", "lgpfit")
  check_type(object, allowed)
  if (class(object) == "lgpfit") {
    out <- object@model
  } else {
    out <- object
  }
  return(out)
}

#' Integer encoding of likelihod function names
#'
#' @description
#' \itemize{
#'   \item \code{likelihood_as_int} converts likelihood name to Stan encoding
#'   \item \code{likelihood_as_str} converts the Stan likelihood encoding
#'   to a string
#'   \item \code{likelihood_list} returns the available likelihood names
#' }
#' @param likelihood a string
#' @param index an integer
#' @name likelihood_encoding

#' @rdname likelihood_encoding
likelihood_list <- function() {
  c("gaussian", "poisson", "nb", "binomial", "bb")
}

#' @rdname likelihood_encoding
likelihood_as_str <- function(index) {
  names <- likelihood_list()
  L <- length(names)
  check_interval(index, 1, L)
  name <- names[index]
  return(name)
}

#' @rdname likelihood_encoding
likelihood_as_int <- function(likelihood) {
  likelihood <- tolower(likelihood)
  allowed <- likelihood_list()
  index <- check_allowed(likelihood, allowed)
  return(index)
}

#' @rdname likelihood_encoding
is_bin_or_bb <- function(likelihood) {
  likelihood %in% c("binomial", "bb")
}

#' @rdname likelihood_encoding
is_pois_or_nb <- function(likelihood) {
  likelihood %in% c("poisson", "nb")
}

#' Link functions and their inverses
#'
#' @param x the input
#' @param likelihood name of the likelihood model
#' @param a a vector which should be divided
#' elementwise by the vector of numbers of trials
#' @param fit an object of class \linkS4class{lgpfit}
#' @returns transformed input
#' @name link
NULL

#' @rdname link
link <- function(x, likelihood) {
  allowed <- likelihood_list()
  check_allowed(likelihood, allowed)
  if (is_pois_or_nb(likelihood)) {
    x <- log(x)
  } else if (is_bin_or_bb(likelihood)) {
    x <- log(x) - log(1 - x)
  }
  return(x)
}

#' @rdname link
link_inv <- function(x, likelihood) {
  allowed <- likelihood_list()
  check_allowed(likelihood, allowed)
  if (is_pois_or_nb(likelihood)) {
    x <- exp(x)
  } else if (is_bin_or_bb(likelihood)) {
    x <- 1 / (1 + exp(-x))
  }
  return(x)
}

#' @rdname link
divide_by_num_trials <- function(a, fit) {
  check_type(fit, "lgpfit")
  likelihood <- get_obs_model(fit)
  if (!is_bin_or_bb(likelihood)) {
    return(a)
  }
  y_num_trials <- get_num_trials(fit)
  check_lengths(a, y_num_trials)
  a / y_num_trials
}

#' Ensure vector has expected length
#'
#' @param len the expected length
#' @param v original vector or just one value that is replicated
#' @return a vector of length \code{len}
ensure_len <- function(v, len) {
  v_name <- deparse(substitute(v))
  L <- length(v)
  if (L == 1) {
    v <- rep(v, len)
  } else if (L != len) {
    msg <- paste0(
      "length of <", v_name, "> was expected to be 1 or ", len,
      ", but found length ", L
    )
    stop(msg)
  }
  return(v)
}

#' Density and quantile functions of the inverse gamma distribution
#'
#' @description Using the same parametrization as Stan. More info
#' \href{https://mc-stan.org/docs/2_24/functions-reference/inverse-gamma-distribution.html}{here}.
#' @param alpha positive real number
#' @param beta positive real number
#' @param x point where to compute the density
#' @param log is log-scale used?
#' @return density/quantile value
#' @name dinvgamma_stanlike
#' @family functions related to the inverse-gamma distribution

#' @rdname dinvgamma_stanlike
dinvgamma_stanlike <- function(x, alpha, beta, log = FALSE) {
  if (alpha <= 0) {
    stop("alpha must be positive")
  }
  if (beta <= 0) {
    stop("beta must be positive")
  }
  t1 <- alpha * log(beta) - lgamma(alpha)
  t2 <- -1 * (alpha + 1) * log(x)
  t3 <- -beta / x
  log_p <- t1 + t2 + t3
  if (log) {
    return(log_p)
  } else {
    return(exp(log_p))
  }
}

#' @param p quantile (must be between 0 and 1)
#' @rdname dinvgamma_stanlike
qinvgamma_stanlike <- function(p, alpha, beta) {
  check_positive(alpha)
  check_positive(beta)
  check_interval(p, 0, 1)
  r <- stats::qgamma(1 - p, shape = alpha, rate = beta)
  return(1 / r)
}

#' Plot colors to use
#'
#' @param main Color name. Must be a valid scheme name for
#' \code{\link[bayesplot]{color_scheme_get}}.
#' @param variant Must be one of {"light", "light_highlight", "mid",
#' "mid_highlight", "dark", "dark_highlight"}.
#' @return A hex value of the color.
#' @family color utilities
colorset <- function(main, variant = "mid") {
  scheme <- bayesplot::color_scheme_get(scheme = main)
  col <- scheme[[variant]]
  if (is.null(col)) {
    stop("Invalid color!")
  }
  return(col)
}

#' A color palettes
#'
#' @param n an integer from 1 to 5
#' @return an array of \code{n} hex values
#' @family color utilities
#' @name color_palette

#' @rdname color_palette
color_palette <- function(n) {
  c1 <- colorset("brightblue", "mid_highlight")
  c2 <- colorset("red", "mid_highlight")
  c3 <- colorset("orange", "mid_highlight")
  c4 <- colorset("green", "mid_highlight")
  c5 <- colorset("gray", "dark_highlight")
  palette <- c(c1, c2, c3, c4, c5)
  palette[1:n]
}

#' @rdname color_palette
fill_palette <- function(n) {
  c1 <- colorset("brightblue", "mid")
  c2 <- colorset("red", "mid")
  c3 <- colorset("orange", "mid")
  c4 <- colorset("green", "mid")
  c5 <- colorset("gray", "dark")
  palette <- c(c1, c2, c3, c4, c5)
  palette[1:n]
}

#' Visualize a color palette
#'
#' @inheritParams color_palette
#' @return a \code{ggplot} object
#' @family color utilities
plot_color_palette <- function(n) {
  colors <- color_palette(n)
  x <- rep(c(0, 1), n)
  y <- rep(c(1:n), each = 2)
  col <- as.factor(rep(colors, each = 2))
  df <- data.frame(x, y, col)
  aes <- ggplot2::aes_string(x = x, y = y, color = col, group = col)
  h <- ggplot2::ggplot(df) +
    ggplot2::geom_line(aes, lwd = 1)
  h <- h + ggplot2::scale_color_manual(values = colors)
  blank <- ggplot2::element_blank()
  h <- h + ggplot2::theme(
    axis.text = blank,
    axis.title = blank,
    axis.ticks = blank
  )
  h <- h + ggplot2::theme(legend.position = "none")
  h <- h + ggplot2::ggtitle("Colors")
  return(h)
}

#' A color scale.
#'
#' @inheritParams color_palette
#' @return a \code{ggplot} object (if \code{n <= 5}) or NULL (if \code{n > 5})
#' @family color utilities
#' @name scale_color

#' @rdname scale_color
scale_color <- function(n) {
  if (n > 5) {
    return(NULL)
  }
  values <- color_palette(n)
  ggplot2::scale_color_manual(values = values)
}

#' @rdname scale_color
scale_fill <- function(n) {
  if (n > 5) {
    return(NULL)
  }
  values <- fill_palette(n)
  ggplot2::scale_fill_manual(values = values)
}


#' A linter-friendly way to call a function
#'
#' @description This exists just to allow calling a function which is a slot
#' of an S4 object, without some linter warnings.
#' @param fun a function which takes one argument
#' @param arg the argument
#' @return The value of \code{fun(arg)}
#' @family function utilities
call_fun <- function(fun, arg) {
  check_type(fun, "function")
  fun(arg)
}

#' Paste function and argument enclosed in parentheses
#'
#' @param s argument name, a string
#' @param fun function name, a string
#' @return a string
#' @family function utilities
enclose_fun <- function(s, fun) {
  paste0(fun, "(", s, ")")
}

#' Remove quotes and whitespace from a string
#'
#' @param s a string
#' @return a string
simplify_str <- function(s) {
  x <- gsub("[[:space:]]", "", s) # remove whitespace
  x <- gsub("[\",\']", "", x) # remove quotes
  return(x)
}

#' Display a runtime estimation message if starting to analyse a large data set
#'
#' @param num_obs number of observations
#' @param threshold threshold for number of observations
#' @return nothing
large_data_msg <- function(num_obs, threshold) {
  msg <- paste0(
    "WARNING: Number of observations is >= ", threshold,
    ", so sampling can take a long time. See the",
    " 'gradient computation took X seconds' information show by",
    " Stan to estimate total runtime."
  )
  msg <- if (num_obs >= threshold) cat(msg)
}

#' Progress bar for iterative functions
#'
#' \itemize{
#'   \item \code{progbar_header} creates header for a progress bar
#'   \item \code{progbar_print} prints part of the bar depending on iteration
#'   index
#' }
#' @name progbar
NULL

#' @rdname progbar
#' @param L length of bar
progbar_header <- function(L) {
  str <- paste0(seq(10, 100, by = 10))
  a <- formatC(str, width = 3)
  str <- paste0("|  ", a, "%")
  top <- paste(formatC(str, width = 3), collapse = "")
  top <- paste0(top, "|")
  barlen <- nchar(top) - 1
  list(
    header = top,
    idx_print = ceiling(seq(1, L, length.out = barlen))
  )
}

#' @rdname progbar
#' @param idx_print indices of iterations to print a bar block
#' @param idx current iteration index
progbar_print <- function(idx, idx_print) {
  N <- length(which(idx_print == idx))
  str <- paste(rep("=", N), collapse = "")
  cat(str)
}


#' Warning message about using a default prior
#'
#' @param desc parameter description
#' @param name parameter name
#' @param model_desc model description
warn_msg_default_prior <- function(desc, name, model_desc) {
  paste0(
    "Using a default prior for ", desc, " (", name, "), in a model",
    " that ", model_desc, ".",
    " This is not recommended. See the 'Basic usage' tutorial",
    " at https://jtimonen.github.io/lgpr-usage/index.html."
  )
}


#' Get number of nonstationary model components
#'
#' @param stan_input a list containing an element named \code{components}
#' @return an integer
get_num_ns <- function(stan_input) {
  comp <- dollar(stan_input, "components")
  num <- sum(comp[, 5] > 0)
  return(num)
}
