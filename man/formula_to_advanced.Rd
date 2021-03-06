% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/formula.R
\name{formula_to_advanced}
\alias{formula_to_advanced}
\alias{rhs_to_advanced}
\title{Parse a model formula that uses the common formula syntax}
\usage{
formula_to_advanced(formula, data)

rhs_to_advanced(rhs, data)
}
\arguments{
\item{formula}{The model formula, where
\itemize{
  \item it must contain exatly one tilde (\code{~}), with response
  variable on the left-hand side and model terms on the right-hand side
  \item terms are be separated by a plus (\code{+}) sign
  \item all variables appearing in \code{formula} must be
  found in \code{data}
}
See the "Model formula syntax" section below (\code{\link{lgp}}) for
instructions on how to specify the model terms.}

\item{data}{A \code{data.frame} where each column corresponds to one
variable, and each row is one observation. Continuous covariates and the
response variable must have type \code{"numeric"} and categorical covariates
must have type \code{"factor"}. Missing values should be indicated with
\code{NaN} or \code{NA}. The response variable cannot contain missing
values. Column names should not contain trailing or leading underscores.}

\item{rhs}{the formula right-hand side in text format}
}
\value{
an object of class \linkS4class{lgpformula}
}
\description{
Translates formula to advanced syntax format.
}
