% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R
\docType{class}
\name{lgpsim-class}
\alias{lgpsim-class}
\alias{lgpsim}
\title{An S4 class to represent a data set simulated using the additive GP
formalism}
\description{
An S4 class to represent a data set simulated using the additive GP
formalism
}
\section{Slots}{

\describe{
\item{\code{data}}{the actual data}

\item{\code{response}}{name of the response variable in the data}

\item{\code{components}}{the drawn function components}

\item{\code{kernel_matrices}}{the covariance matrices for each gp}

\item{\code{info}}{A list with fields
\itemize{
  \item \code{par_ell} the used lengthscale parameters
  \item \code{par_cont} the parameters used to generate the continuous
  covariates
  \item \code{p_signal} signal proportion
}}

\item{\code{effect_times}}{A list with fields
\itemize{
  \item \code{true} possible true effect times that generate the disease
  effect
  \item \code{observed} possible observed effect times
}}
}}

\seealso{
For visualizing, see \code{\link{plot_sim}}.
}
