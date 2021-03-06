% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/AllClasses.R
\docType{class}
\name{GaussianPrediction-class}
\alias{GaussianPrediction-class}
\alias{GaussianPrediction}
\title{An S4 class to represent an analytically computed posterior or prior
predictive distribution (Gaussian) of an additive GP model}
\description{
An S4 class to represent an analytically computed posterior or prior
predictive distribution (Gaussian) of an additive GP model
}
\section{Slots}{

\describe{
\item{\code{f_comp_mean}}{component means}

\item{\code{f_comp_std}}{component standard deviations}

\item{\code{f_mean}}{signal mean (on normalized scale)}

\item{\code{f_std}}{signal standard deviation (on normalized scale)}

\item{\code{y_mean}}{predictive mean (on original data scale)}

\item{\code{y_std}}{predictive standard deviation (on original data scale)}
}}

\seealso{
\linkS4class{Prediction}
}
