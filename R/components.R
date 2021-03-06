#' Parse the covariates and model components from given data and formula
#'
#' @inheritParams parse_response
#' @param x_cont_scl Information on how to scale the continuous covariates.
#' This can either be
#' \itemize{
#'   \item an existing list of objects with class \linkS4class{lgpscaling}, or
#'   \item \code{NA}, in which case such list is created by computing mean
#'   and standard deviation from \code{data}
#' }
#'
#' @return parsed input to stan and covariate scaling
parse_covs_and_comps <- function(data, model_formula, x_cont_scl) {

  # Check that all covariates exist in data
  x_names <- rhs_variables(model_formula@terms)
  x_names <- unique(x_names)
  for (name in x_names) check_in_data(name, data)

  # Create the inputs to Stan
  covariates <- stan_data_covariates(data, x_names, x_cont_scl)
  components <- stan_data_components(model_formula, covariates)
  ts1 <- dollar(covariates, "to_stan")
  ts2 <- dollar(components, "to_stan")

  # Return
  list(
    to_stan = c(ts1, ts2),
    x_cont_scalings = dollar(covariates, "x_cont_scalings"),
    x_cat_levels = dollar(covariates, "x_cat_levels"),
    caseid_map = dollar(components, "caseid_map")
  )
}

#' Create covariate data for Stan input
#'
#' @description Creates the following Stan data input list fields:
#' \itemize{
#'   \item \code{num_cov_cat}
#'   \item \code{num_cov_cont}
#'   \item \code{x_cat}
#'   \item \code{x_cat_num_levels}
#'   \item \code{x_cont}
#'   \item \code{x_cont_unnorm}
#'   \item \code{x_cont_mask}
#' }
#' @inheritParams parse_covs_and_comps
#' @param data a data frame
#' @param x_names unique covariate names
#' @return a named list with fields
#' \itemize{
#'   \item \code{to_stan}: a list of stan data
#'   \item \code{x_cont_scaling}: normalization function and inverse for each
#'   continuous covariate
#'   \item \code{x_cat_levels}: names of the levels of each categorical
#'   covariate before conversion from factor to numeric
#' }
stan_data_covariates <- function(data, x_names, x_cont_scl) {
  check_not_null(x_cont_scl)
  num_obs <- dim(data)[1]
  scl_exists <- is.list(x_cont_scl)

  x_cont <- list()
  x_cont_mask <- list()
  x_cont_unnorm <- list()
  x_cont_scl_new <- list()
  x_cont_names <- c()

  x_cat <- list()
  x_cat_levels <- list()
  x_cat_num_levels <- c()
  x_cat_names <- c()

  num_cat <- 0
  num_cont <- 0

  for (name in x_names) {
    X_RAW <- data[[name]]
    c_x <- class(X_RAW)[1]
    if (c_x == "factor") {

      # A categorical covariate
      num_cat <- num_cat + 1
      n_na <- sum(is.na(X_RAW))
      if (n_na > 0) {
        msg <- paste0(n_na, " missing values for factor '", name, "'!")
        stop(msg)
      }
      x_cat[[num_cat]] <- as.numeric(X_RAW)
      x_cat_num_levels[num_cat] <- length(levels(X_RAW))
      x_cat_levels[[num_cat]] <- levels(X_RAW)
      x_cat_names[num_cat] <- name
    } else if (c_x == "numeric") {

      # A continuous covariate
      num_cont <- num_cont + 1
      is_na <- is.na(X_RAW)
      x_cont_mask[[num_cont]] <- as.numeric(is_na)
      X_NONAN <- X_RAW
      X_NONAN[is_na] <- 0
      new_normalizer <- create_scaling(X_NONAN, name)
      x_cont_scl_new[[num_cont]] <- new_normalizer
      normalizer <- if (scl_exists) x_cont_scl[[num_cont]] else new_normalizer
      x_cont[[num_cont]] <- call_fun(normalizer@fun, X_NONAN)
      x_cont_unnorm[[num_cont]] <- X_NONAN
      x_cont_names[num_cont] <- name
    } else {
      msg <- paste0("class(", name, ")[1] is invalid (", c_x, ")")
      stop(msg)
    }
  }

  # Convert lists to matrices
  x_cat <- list_to_matrix(x_cat, num_obs)
  x_cont <- list_to_matrix(x_cont, num_obs)
  x_cont_unnorm <- list_to_matrix(x_cont_unnorm, num_obs)
  x_cont_mask <- list_to_matrix(x_cont_mask, num_obs)

  # Name lists and matrix rows
  x_cont_scalings <- if (scl_exists) x_cont_scl else x_cont_scl_new
  names(x_cont_scalings) <- x_cont_names
  names(x_cat_levels) <- x_cat_names
  rownames(x_cat) <- x_cat_names
  rownames(x_cont) <- x_cont_names
  rownames(x_cont_unnorm) <- x_cont_names
  rownames(x_cont_mask) <- x_cont_names

  if (!is.null(x_cat_num_levels)) {
    x_cat_num_levels <- array(x_cat_num_levels, dim = c(num_cat))
  } else {
    x_cat_num_levels <- array(0, dim = c(0))
  }

  # Create Stan data
  to_stan <- list(
    num_cov_cont = num_cont,
    num_cov_cat = num_cat,
    x_cat = x_cat,
    x_cat_num_levels = x_cat_num_levels,
    x_cont = x_cont,
    x_cont_unnorm = x_cont_unnorm,
    x_cont_mask = x_cont_mask
  )

  # Return
  list(
    to_stan = to_stan,
    x_cont_scalings = x_cont_scalings,
    x_cat_levels = x_cat_levels
  )
}


#' Create model components data for Stan input
#'
#' @param model_formula an object of class \linkS4class{lgpformula}
#' @param covariates a list returned by \code{\link{stan_data_covariates}}
#' @return a named list with fields
#' \itemize{
#'   \item \code{to_stan}: a list of stan data
#'   \item \code{caseid_map}: a data frame
#' }
stan_data_components <- function(model_formula, covariates) {
  components <- create_components_encoding(model_formula, covariates)

  # Create idx_expand, num_cases and vm_params
  cts <- dollar(covariates, "to_stan")
  x_cat <- dollar(cts, "x_cat")
  x_cont_mask <- dollar(cts, "x_cont_mask")
  lst <- create_idx_expand(components, x_cat, x_cont_mask)
  idx_expand <- dollar(lst, "idx_expand")
  caseid_map <- dollar(lst, "map")
  num_bt <- length(unique(idx_expand[idx_expand > 1]))
  num_ns <- sum(components[, 5] != 0)
  num_vm <- sum(components[, 6] != 0)
  VM <- default_vm_params()
  vm_params <- matrix(rep(VM, num_ns), num_ns, 2, byrow = TRUE)

  to_stan <- list(
    components = components,
    idx_expand = idx_expand,
    num_bt = num_bt,
    num_ell = sum(components[, 1] != 0),
    num_heter = sum(components[, 4] != 0),
    num_ns = num_ns,
    num_vm = num_vm,
    num_uncrt = sum(components[, 7] != 0),
    num_comps = dim(components)[1],
    vm_params = vm_params
  )

  # Return
  list(
    to_stan = to_stan,
    caseid_map = caseid_map
  )
}


#' Create the components integer array
#'
#' @inheritParams stan_data_components
#' @return a matrix of integers
create_components_encoding <- function(model_formula, covariates) {
  terms <- model_formula@terms@summands
  J <- length(terms)
  comps <- array(0, dim = c(J, 9))
  for (j in seq_len(J)) {
    comps[j, ] <- term_to_numeric(terms[[j]], covariates)
  }
  colnames(comps) <- c(
    "type", "ker", "unused",
    "het", "ns", "vm",
    "unc", "cat", "cont"
  )
  rownames(comps) <- term_names(model_formula@terms)
  as.matrix(comps)
}

#' Map a list of terms to their "names"
#'
#' @param rhs an object of class \linkS4class{lgprhs}
#' @return a character vector
term_names <- function(rhs) {
  terms <- rhs@summands
  J <- length(terms)
  names <- c()
  for (j in seq_len(J)) {
    term <- terms[[j]]
    names <- c(names, as.character(term))
  }
  return(names)
}


#' An lgpterm to numeric representation for Stan
#'
#' @param term an object of class \linkS4class{lgpterm}
#' @param covariates a list returned by \code{\link{stan_data_covariates}}
#' @return a vector of 9 integers
term_to_numeric <- function(term, covariates) {
  out <- rep(0, 9)

  # Check formula validity
  parsed <- check_term_factors(term)

  # Check component type
  is_gp <- !is.null(dollar(parsed, "gp_kernel"))
  is_cat <- !is.null(dollar(parsed, "cat_kernel"))
  if (!is_gp) {
    ctype <- 0
  } else {
    ctype <- if (is_cat) 2 else 1
  }
  out[1] <- ctype

  # Check kernel type
  if (is_cat) {
    ker <- dollar(parsed, "cat_kernel")
    idx <- check_allowed(ker, allowed = c("zs", "categ"))
    ktype <- idx - 1
  } else {
    ktype <- 0
  }
  out[2] <- ktype

  # Check nonstationary options
  gpk <- dollar(parsed, "gp_kernel")
  if (!is.null(gpk)) {
    is_warped <- gpk %in% c("gp_ns", "gp_vm")
    is_vm <- gpk == "gp_vm"
  } else {
    is_warped <- FALSE
    is_vm <- FALSE
  }

  out[5] <- as.numeric(is_warped)
  out[6] <- as.numeric(is_vm)

  # Check covariate types
  cidx <- check_term_covariates(covariates, parsed)
  out[4] <- cidx[1]
  out[7] <- cidx[2]
  out[8] <- cidx[3]
  out[9] <- cidx[4]

  return(out)
}

#' Helper for converting an lgpterm to numeric representation for Stan
#'
#' @param covariates a list returned by \code{\link{stan_data_covariates}}
#' @param pf a list returned by \code{\link{check_term_factors}}
#' @return two integers
check_term_covariates <- function(covariates, pf) {
  cts <- dollar(covariates, "to_stan")
  cat_names <- rownames(dollar(cts, "x_cat"))
  cont_names <- rownames(dollar(cts, "x_cont"))
  nams <- list(categorical_names = cat_names, continuous_names = cont_names)

  check_type <- function(cov_name, allowed, type, fun) {
    idx <- which(allowed == cov_name)
    if (length(idx) < 1) {
      msg <- paste0(
        "The argument for <", fun, "> must be a name of a ",
        type, " covariate. Found = ", cov_name, "."
      )
      stop(msg)
    }
    return(idx)
  }

  out <- c(0, 0, 0, 0)
  funs <- c("het", "unc", "cat", "gp")
  types <- c("categorical", "categorical", "categorical", "continuous")
  fields <- c("", "", "cat_kernel", "gp_kernel")
  for (j in 1:4) {
    fun_covariate <- paste0(funs[j], "_covariate")
    names_type <- paste0(types[j], "_names")
    type_names <- nams[[names_type]]
    is_type <- !is.null(pf[[fun_covariate]])
    if (is_type) {
      cov_name <- pf[[fun_covariate]]
      fie <- fields[j]
      if (nchar(fie) == 0) {
        field <- funs[[j]]
      } else {
        field <- pf[[fie]]
      }
      idx <- check_type(cov_name, type_names, types[j], field)
    } else {
      idx <- 0
    }
    out[j] <- idx
  }

  # Return
  out
}

#' Helper for converting an lgpterm to numeric representation for Stan
#'
#' @param term an object of class \linkS4class{lgpterm}
#' @return a named list
check_term_factors <- function(term) {

  # Check for het() expressions
  facs <- term@factors
  reduced <- reduce_factors_expr(facs, "het")
  facs <- dollar(reduced, "factors")
  het_covariate <- dollar(reduced, "covariate")

  # Check for unc() expressions
  reduced <- reduce_factors_expr(facs, "unc")
  facs <- dollar(reduced, "factors")
  unc_covariate <- dollar(reduced, "covariate")

  # Check compatibility
  if (!is.null(unc_covariate) && !is.null(het_covariate)) {
    is_compatible <- (unc_covariate == het_covariate)
    if (!is_compatible) {
      msg <- paste0(
        "Names of the covariates in unc() and het() ",
        "expressions must match! Found = {",
        unc_covariate, ", ", het_covariate, "}."
      )
      stop(msg)
    }
  }

  # Check for gp, gp_ns and gp_vm expressions
  reduced <- reduce_factors_gp(facs)
  facs <- dollar(reduced, "factors")
  gp_covariate <- dollar(reduced, "covariate")
  gp_kernel <- dollar(reduced, "kernel")

  # Check for categorical kernel expression
  D <- length(facs)
  if (D == 0) {
    cat_covariate <- NULL
    cat_kernel <- NULL
  } else if (D == 1) {
    cat_covariate <- facs[[1]]@covariate
    cat_kernel <- facs[[1]]@fun
  } else {
    msg <- paste0(
      "Invalid term with expressions: ", as.character(term),
      ". Note that each term can contain at most one categ()",
      " or zs() expression."
    )
    stop(msg)
  }

  # Return a named list
  list(
    gp_covariate = gp_covariate,
    gp_kernel = gp_kernel,
    cat_covariate = cat_covariate,
    cat_kernel = cat_kernel,
    unc_covariate = unc_covariate,
    het_covariate = het_covariate
  )
}

#' Check for certain expressions in a term
#'
#' @param factors list of \linkS4class{lgpexpr} objects
#' @param expr the expression name to check
#' @return an updated list with no \code{expr} expressions, and name of
#' the covariate in the original \code{expr} expression
reduce_factors_expr <- function(factors, expr) {
  fun <- function(x) {
    x@fun == expr
  }
  idx <- which(sapply(factors, fun))
  H <- length(idx)
  if (H > 1) {
    msg <- paste0(
      "cannot have more than one '", expr, "' expression ",
      "in one term! found = ", H
    )
    stop(msg)
  }
  if (H == 1) {
    covariate <- factors[[idx]]@covariate
    factors[[idx]] <- NULL
  } else {
    covariate <- NULL
  }
  if (length(factors) < 1) {
    msg <- paste0(
      "there must be one gp(), gp_ns() or gp_vm() expression",
      " in each term involving the '", expr, "' expression!"
    )
    stop(msg)
  }
  list(factors = factors, covariate = covariate)
}

#' Check for gp expressions in a term
#'
#' @param factors list of \linkS4class{lgpexpr} objects
#' @return an updated list with no \code{gp*} expressions, and name of
#' the covariate in the original \code{gp*} expression
reduce_factors_gp <- function(factors) {
  fun <- function(x) {
    gp_names <- c("gp", "gp_ns", "gp_vm")
    x@fun %in% gp_names
  }
  idx <- which(sapply(factors, fun))
  H <- length(idx)
  if (H > 1) {
    msg <- paste0(
      "cannot have more than one gp(), gp_ns() or gp_vm() expression ",
      "in one term! found = ", H
    )
    stop(msg)
  }
  if (H == 1) {
    covariate <- factors[[idx]]@covariate
    kernel <- factors[[idx]]@fun
    factors[[idx]] <- NULL
  } else {
    covariate <- NULL
    kernel <- NULL
  }
  list(factors = factors, covariate = covariate, kernel = kernel)
}
