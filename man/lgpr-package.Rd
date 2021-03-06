% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lgpr.R
\docType{package}
\name{lgpr-package}
\alias{lgpr-package}
\alias{lgpr}
\title{The 'lgpr' package.}
\description{
\itemize{
  \item A package for Bayesian additive Gaussian process (GP) modeling with
interpretable kernels designed for longitudinal data.
  \item Features inference of covariate effects
  and covariate relevance assesment.
  \item Models can include non-stationary, heterogeneous and temporally
uncertain effects.
  \item Bayesian inference of the model (hyper)parameters using
\code{\link[rstan]{rstan}}.
  \item  Functions for visualizing longitudinal data,
posterior draws, model predictions and inferred covariate effects are
also provided.
}
}
\section{Overview}{

See the documentation of
\itemize{
 \item \code{\link{lgp}} for info on how to specify and fit models
 \item \code{\link{ppc}} for prior and posterior predictive checks
 \item \code{\link{relevances}} for component/covariate relevance assessment
 \item \code{\link{select}} for component/covariate selection
 \item \code{\link{get_pred}} for model predictions and inferred components
 at data points
 \item \code{\link{pred}} for computing out-of-sample predictions and
 inferred components
 \item \code{\link{plot_pred}} and \code{\link{plot_f}} for visualizing
 predictions and inferred components
}
}

\section{Tutorials}{

See tutorials at \url{https://jtimonen.github.io/lgpr-usage/index.html}.
}

\section{Citation}{

Run \code{citation("lgpr")} to get citation information.
}

\section{Feedback}{

Bug reports, PRs, enchancement ideas or user experiences in general are
welcome and appreciated. Create an issue in Github or email the author.
}

\references{
\enumerate{
  \item Carpenter, B. et al. (2017).
  \emph{Stan: A probabilistic programming language}. Journal of Statistical
   Software 76(1).
  \item Jonah Gabry, Ben Goodrich and Martin Lysy (2019).
  \emph{rstantools: Tools for Developing R Packages Interfacing with 'Stan'}.
  R package version 2.0.0.
  \item Gabry, J. and Mahr, T. (2019).
  \emph{bayesplot: Plotting for Bayesian Models}. R package version 1.7.0,
   http://mc-stan.org/bayesplot.
  \item Stan Development Team (2019). \emph{RStan: the R interface to Stan.}
  R package version 2.19.2. http://mc-stan.org/.
}
}
\author{
Juho Timonen (first.last at iki.fi)
}
\keyword{Gaussian}
\keyword{Stan,}
\keyword{covariate}
\keyword{data,}
\keyword{interpretable}
\keyword{longitudinal}
\keyword{models}
\keyword{processes,}
\keyword{relevances,}
