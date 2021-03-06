% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/MethodsModel.R
\name{model_getters}
\alias{model_getters}
\alias{get_stan_input}
\alias{get_data}
\alias{get_num_obs}
\alias{is_f_sampled}
\alias{is_yrng_done}
\alias{get_obs_model}
\alias{get_num_trials}
\title{Functions that access model properties}
\usage{
get_stan_input(object)

get_data(object)

get_num_obs(object)

is_f_sampled(object)

is_yrng_done(object)

get_obs_model(object)

get_num_trials(object)
}
\arguments{
\item{object}{an object of class \linkS4class{lgpmodel} or
\linkS4class{lgpfit}}
}
\value{
\itemize{
  \item \code{get_stan_input} returns a list
  \item \code{get_num_obs} returns the number of observations
  \item \code{get_obs_model} returns the obs. model as a string
  \item \code{get_y_name} returns the response variable name
  \item \code{get_data} returns the original unmodified data frame
  \item \code{get_num_trials} returns the vector of numbers of trials
  \item \code{is_f_sampled} returns a boolean value
}
}
\description{
Functions that access model properties
}
