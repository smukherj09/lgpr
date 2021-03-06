% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pred.R
\name{pred.kr_h}
\alias{pred.kr_h}
\title{Map the sum f from pred.kr_compute to h}
\usage{
pred.kr_h(fit, f, c_hat_pred, verbose)
}
\arguments{
\item{fit}{An object of class \linkS4class{lgpfit}.}

\item{f}{an array of shape (num_draws, num_pred_points)}

\item{c_hat_pred}{This is only used if the latent signal \code{f} was
sampled. This input contains the values added to the sum \code{f} before
passing through inverse link function. Must be a vector with length equal to
the number of prediction points. If original \code{c_hat} was constant,
then \code{c_hat_pred} can be ignored, in which case this will by default
use the same constant.}

\item{verbose}{Should more information and a progress bar be printed?}
}
\value{
an array with same shape as \code{f}
}
\description{
Map the sum f from pred.kr_compute to h
}
