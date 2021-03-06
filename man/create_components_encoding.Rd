% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/components.R
\name{create_components_encoding}
\alias{create_components_encoding}
\title{Create the components integer array}
\usage{
create_components_encoding(model_formula, covariates)
}
\arguments{
\item{model_formula}{an object of class \linkS4class{lgpformula}}

\item{covariates}{a list returned by \code{\link{stan_data_covariates}}}
}
\value{
a matrix of integers
}
\description{
Create the components integer array
}
