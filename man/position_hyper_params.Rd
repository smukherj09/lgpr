% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/priors_parse.R
\name{position_hyper_params}
\alias{position_hyper_params}
\title{Position the hyper parameters from a list to a vector that goes to Stan}
\usage{
position_hyper_params(desc)
}
\arguments{
\item{desc}{Hyperparameters as a named list}
}
\value{
three real numbers
}
\description{
Position the hyper parameters from a list to a vector that goes to Stan
}
\seealso{
Other prior parsers: 
\code{\link{parse_prior_full}()},
\code{\link{parse_prior_single}()},
\code{\link{prior_to_num}()}
}
\concept{prior parsers}
