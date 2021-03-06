#' Validate S4 class objects
#'
#' @param object an object to validate
#' @return \code{TRUE} if valid, otherwise reasons for invalidity
#' @name validate
NULL

#' @rdname validate
check_lgpexpr <- function(object) {
  errors <- character()
  v0 <- nchar(object@covariate) > 0
  valid_funs <- c(
    "gp", "gp_ns", "gp_vm", "categ", "zs", "het", "unc"
  )
  v1 <- object@fun %in% valid_funs
  if (!v0) {
    errors <- c(errors, "covariate name cannot be empty")
  }
  if (!v1) {
    str <- paste0(valid_funs, collapse = ", ")
    msg <- paste0(
      "<fun> must be one of {", str,
      "}, found = '", object@fun, "'"
    )
    errors <- c(errors, msg)
  }
  if (length(errors) == 0) TRUE else errors
}

#' @rdname validate
check_lgpformula <- function(object) {
  covs <- rhs_variables(object@terms)
  r <- object@y_name
  errors <- character()
  if (r %in% covs) {
    msg <- "the response variable cannot be also a covariate"
    errors <- c(errors, msg)
  }
  if (length(errors) == 0) TRUE else errors
}

#' @rdname validate
check_lgpscaling <- function(object) {
  a <- 1.2321
  a_mapped <- call_fun(object@fun, a)
  b <- call_fun(object@fun_inv, a_mapped)
  diff <- abs(a - b)
  errors <- character()
  if (diff > 1e-6) {
    err <- paste("<f_inv> is not an inverse function of <f>, diff = ", diff)
    errors <- c(errors, err)
  }
  if (nchar(object@var_name) < 1) {
    err <- "variable name length must be at least 1 character"
    errors <- c(errors, err)
  }
  out <- if (length(errors) > 0) errors else TRUE
  return(out)
}

#' @rdname validate
check_GaussianPrediction <- function(object) {
  errors <- c()
  f_comp_mean <- object@f_comp_mean
  f_comp_std <- object@f_comp_std
  errors <- c(errors, validate_lengths(f_comp_mean, f_comp_std))
  D1 <- dim(object@f_mean)
  D2 <- dim(object@f_std)
  D3 <- dim(object@y_mean)
  D4 <- dim(object@y_std)
  D <- list(D1, D2, D3, D4)
  L <- length(f_comp_mean)
  for (j in seq_len(L)) {
    m <- object@f_comp_mean[[j]]
    s <- object@f_comp_std[[j]]
    D <- c(D, list(dim(m), dim(s)))
  }
  errors <- c(errors, validate_dimension_list(D))
  out <- if (length(errors) > 0) errors else TRUE
  return(out)
}

#' @rdname validate
check_Prediction <- function(object) {
  L <- length(object@f_comp)
  errors <- c()
  D1 <- dim(object@f)
  D2 <- dim(object@h)
  D <- list(D1, D2)
  for (j in seq_len(L)) {
    fj <- object@f_comp[[j]]
    D <- c(D, list(dim(fj)))
  }
  errors <- c(errors, validate_dimension_list(D))
  out <- if (length(errors) > 0) errors else TRUE
  return(out)
}

#' An S4 class to represent an lgp expression
#'
#' @slot covariate name of a covariate
#' @slot fun function name
#' @seealso See \code{\link{operations}} for performing arithmetics
#' on \linkS4class{lgprhs}, \linkS4class{lgpterm} and \linkS4class{lgpexpr}
#' objects.
lgpexpr <- setClass("lgpexpr",
  representation = representation(
    covariate = "character",
    fun = "character"
  ),
  prototype(covariate = "", fun = ""),
  validity = check_lgpexpr
)

#' An S4 class to represent one formula term
#'
#' @slot factors a list of at most two \linkS4class{lgpexpr}s
#' @seealso See \code{\link{operations}} for performing arithmetics
#' on \linkS4class{lgprhs}, \linkS4class{lgpterm} and \linkS4class{lgpexpr}
#' objects.
lgpterm <- setClass("lgpterm", slots = c(factors = "list"))

#' An S4 class to represent the right-hand side of an lgp formula
#'
#' @slot summands a list of one or more \linkS4class{lgpterm}s
#' @seealso See \code{\link{operations}} for performing arithmetics
#' on \linkS4class{lgprhs}, \linkS4class{lgpterm} and \linkS4class{lgpexpr}
#' objects.
lgprhs <- setClass("lgprhs", slots = c(summands = "list"))

#' An S4 class to represent an lgp formula
#'
#' @slot terms an object of class \linkS4class{lgprhs}
#' @slot y_name name of the response variable
#' @slot call original formula call
#' @seealso See \code{\link{operations}} for performing arithmetics
#' on \linkS4class{lgprhs}, \linkS4class{lgpterm} and \linkS4class{lgpexpr}
#' objects.
lgpformula <- setClass("lgpformula",
  representation = representation(
    call = "character",
    y_name = "character",
    terms = "lgprhs"
  ),
  validity = check_lgpformula
)

#' An S4 class to represent variable scaling and its inverse
#'
#' @slot fun function that performs normalization
#' @slot fun_inv inverse function of \code{fun}
#' @slot var_name variable name
lgpscaling <- setClass("lgpscaling",
  representation = representation(
    fun = "function",
    fun_inv = "function",
    var_name = "character"
  ),
  prototype = prototype(
    fun = function(x) {
      x
    },
    fun_inv = function(x) {
      x
    },
    var_name = "unknown"
  ),
  validity = check_lgpscaling
)

#' An S4 class to represent an lgp model
#'
#' @slot formula An object of class \linkS4class{lgpformula}
#' @slot data The original unmodified data.
#' @slot stan_dat The data to be given as input to \code{rstan::sampling}
#' @slot var_names List of variable names grouped by type.
#' @slot var_scalings A named list with fields
#' \itemize{
#'   \item \code{y} - Response variable normalization function and its
#'   inverse operation. Must be an \linkS4class{lgpscaling} object.
#'   \item \code{x_cont} - Continous covariate normalization functions and
#'   their inverse operations. Must be a named list with each element is an
#'   \linkS4class{lgpscaling} object.
#' }
#' @slot var_info A named list with fields
#' \itemize{
#'   \item \code{x_cat_levels} - Names of the levels of categorical covariates
#'   before converting from factor to numeric.
#' }
#' @slot info Other info in text format.
#' @slot stan_model_name Name of Stan model.
#' @slot full_prior Complete prior information.
#' @seealso
#' \code{\link{model_getters}}
lgpmodel <- setClass("lgpmodel",
  representation = representation(
    model_formula = "lgpformula",
    data = "data.frame",
    stan_input = "list",
    var_names = "list",
    var_scalings = "list",
    var_info = "list",
    info = "list",
    stan_model_name = "character",
    full_prior = "list"
  )
)

#' An S4 class to represent the output of the \code{lgp} function
#'
#' @slot stan_fit An object of class \code{stanfit}.
#' @slot model An object of class \code{lgpmodel}.
#' @family model fit vizualization functions
#' @seealso  All methods that work on \linkS4class{lgpmodel}
#' objects work also on \linkS4class{lgpfit} objects.
#' @seealso For complete info on accessing the properties of the
#' \code{stan_fit} slot, see
#' \href{https://cran.r-project.org/web/packages/rstan/vignettes/stanfit-objects.html}{here}.
lgpfit <- setClass("lgpfit",
  slots = c(
    stan_fit = "stanfit",
    model = "lgpmodel"
  )
)

#' An S4 class to represent a data set simulated using the additive GP
#' formalism
#'
#' @slot data the actual data
#' @slot response name of the response variable in the data
#' @slot components the drawn function components
#' @slot kernel_matrices the covariance matrices for each gp
#' @slot info A list with fields
#' \itemize{
#'   \item \code{par_ell} the used lengthscale parameters
#'   \item \code{par_cont} the parameters used to generate the continuous
#'   covariates
#'   \item \code{p_signal} signal proportion
#' }
#' @slot effect_times A list with fields
#' \itemize{
#'   \item \code{true} possible true effect times that generate the disease
#'   effect
#'   \item \code{observed} possible observed effect times
#' }
#' @seealso
#' For visualizing, see \code{\link{plot_sim}}.
lgpsim <- setClass("lgpsim",
  representation = representation(
    data = "data.frame",
    response = "character",
    components = "data.frame",
    kernel_matrices = "array",
    effect_times = "list",
    info = "list"
  )
)

#' An S4 class to represent an analytically computed posterior or prior
#' predictive distribution (Gaussian) of an additive GP model
#'
#' @slot f_comp_mean component means
#' @slot f_comp_std component standard deviations
#' @slot f_mean signal mean (on normalized scale)
#' @slot f_std signal standard deviation (on normalized scale)
#' @slot y_mean predictive mean (on original data scale)
#' @slot y_std predictive standard deviation (on original data scale)
#' @seealso \linkS4class{Prediction}
GaussianPrediction <- setClass("GaussianPrediction",
  representation = representation(
    f_comp_mean = "list",
    f_comp_std = "list",
    f_mean = "matrix",
    f_std = "matrix",
    y_mean = "matrix",
    y_std = "matrix"
  ),
  validity = check_GaussianPrediction
)

#' An S4 class to represent general additive model predictions
#'
#' @slot f_comp component predictions
#' @slot f signal prediction
#' @slot h prediction (signal prediction transformed through inverse link
#' function)
#' @seealso \linkS4class{GaussianPrediction}
Prediction <- setClass("Prediction",
  representation = representation(
    f_comp = "list",
    f = "matrix",
    h = "matrix"
  ),
  validity = check_Prediction
)


#' Check that all listed dimensions are equal
#'
#' @param dims a list of dimensions
#' @return list of errors or NULL
validate_dimension_list <- function(dims) {
  errors <- c()
  L <- length(dims)
  d1 <- dims[[1]]
  K <- length(d1)
  for (j in seq_len(L)) {
    dj <- dims[[j]]
    for (k in seq_len(K)) {
      if (dj[k] != d1[k]) {
        msg <- paste0(k, "th dimensions of elements 1 and ", j, " differ!")
        errors <- c(errors, msg)
      }
    }
  }
  return(errors)
}


#' Check that arguments have equal lengths
#'
#' @param a first argument
#' @param b second argument
#' @return list of errors or NULL
validate_lengths <- function(a, b) {
  errors <- c()
  L1 <- length(a)
  L2 <- length(b)
  if (L1 != L2) {
    msg <- "lengths do not agree!"
    errors <- c(errors, msg)
  }
  return(errors)
}
