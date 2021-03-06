% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model.R
\name{parse_response}
\alias{parse_response}
\title{Parse the response variable from given data and formula}
\usage{
parse_response(data, likelihood, model_formula)
}
\arguments{
\item{data}{A \code{data.frame} where each column corresponds to one
variable, and each row is one observation. Continuous covariates and the
response variable must have type \code{"numeric"} and categorical covariates
must have type \code{"factor"}. Missing values should be indicated with
\code{NaN} or \code{NA}. The response variable cannot contain missing
values. Column names should not contain trailing or leading underscores.}

\item{likelihood}{Determines the observation model. Must be either
\code{"gaussian"} (default), \code{"poisson"}, \code{"nb"} (negative
binomial), \code{"binomial"} or \code{"bb"} (beta binomial).}

\item{model_formula}{An object of class \code{lgpformula}.}
}
\value{
a named list of parsed options
}
\description{
Parse the response variable from given data and formula
}
