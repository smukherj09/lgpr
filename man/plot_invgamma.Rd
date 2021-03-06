% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_misc.R
\name{plot_invgamma}
\alias{plot_invgamma}
\title{Plot the inverse gamma-distribution pdf}
\usage{
plot_invgamma(
  alpha,
  beta,
  by = 0.01,
  log = FALSE,
  IQR = 0.95,
  return_quantiles = FALSE,
  linecolor = colorset("red", "dark"),
  fillcolor = colorset("red", "mid")
)
}
\arguments{
\item{alpha}{positive real number}

\item{beta}{positive real number}

\item{by}{grid size}

\item{log}{is log-scale used?}

\item{IQR}{inter-quantile range width}

\item{return_quantiles}{should this return a list}

\item{linecolor}{line color}

\item{fillcolor}{fill color}
}
\value{
a \code{ggplot} object
}
\description{
Plot the inverse gamma-distribution pdf
}
\seealso{
Other functions related to the inverse-gamma distribution: 
\code{\link{dinvgamma_stanlike}()},
\code{\link{priors}}
}
\concept{functions related to the inverse-gamma distribution}
