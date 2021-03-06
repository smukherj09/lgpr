% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/components.R
\name{reduce_factors_expr}
\alias{reduce_factors_expr}
\title{Check for certain expressions in a term}
\usage{
reduce_factors_expr(factors, expr)
}
\arguments{
\item{factors}{list of \linkS4class{lgpexpr} objects}

\item{expr}{the expression name to check}
}
\value{
an updated list with no \code{expr} expressions, and name of
the covariate in the original \code{expr} expression
}
\description{
Check for certain expressions in a term
}
