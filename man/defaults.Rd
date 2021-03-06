% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/defaults.R
\name{defaults}
\alias{defaults}
\alias{default_vm_params}
\alias{default_prior}
\alias{default_prior_common}
\alias{default_prior_effect_time_info}
\alias{default_ppc_fun}
\title{Default priors and parameter values}
\usage{
default_vm_params()

default_prior(name, num_uncrt = NULL)

default_prior_common(name)

default_prior_effect_time_info(num_uncrt)

default_ppc_fun(object)
}
\arguments{
\item{name}{parameter name}

\item{num_uncrt}{number of uncertain components}

\item{object}{an object of class \linkS4class{lgpfit} or \code{lgpmodel}}
}
\value{
see description
}
\description{
\itemize{
  \item \code{default_vm_params} returns variance mask function parameters
  (two numbers)
  \item \code{default_prior} returns a named list that defines a prior
  \item \code{default_ppc_fun} returns a function to be used as argument
  of \code{\link{ppc}}
}
}
