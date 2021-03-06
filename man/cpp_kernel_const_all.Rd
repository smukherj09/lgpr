% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/stanfunctions.R
\name{cpp_kernel_const_all}
\alias{cpp_kernel_const_all}
\title{Compute all constant kernel matrices of a model}
\usage{
cpp_kernel_const_all(
  n1,
  n2,
  x1_cat,
  x2_cat,
  x1_cont_mask,
  x2_cont_mask,
  x_cat_num_levels,
  components,
  STREAM = get_stream()
)
}
\arguments{
\item{n1}{integer}

\item{n2}{integer}

\item{x1_cat}{categorical covariates}

\item{x2_cat}{categorical covariates}

\item{x1_cont_mask}{continuous covariate masks}

\item{x2_cont_mask}{continuous covariate masks}

\item{x_cat_num_levels}{number of levels for each categorical covariate}

\item{components}{an integer array}

\item{STREAM}{an external pointer}
}
\value{
an array of kernel matrices
}
\description{
This is a wrapper for \code{STAN_kernel_const_all}
}
