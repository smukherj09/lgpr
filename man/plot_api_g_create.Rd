% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot_api.R
\name{plot_api_g_create}
\alias{plot_api_g_create}
\title{Initialize a grouped plot}
\usage{
plot_api_g_create(df_data, i_test, nrow, ncol)
}
\arguments{
\item{df_data}{A data frame containing the observations.}

\item{i_test}{Indices of test points.}

\item{nrow}{number of rows, an argument for
\code{\link[ggplot2]{facet_wrap}}}

\item{ncol}{number of columns, an argument for
\code{\link[ggplot2]{facet_wrap}}}
}
\value{
a \code{ggplot} object
}
\description{
Initialize a grouped plot
}
\seealso{
Other plot_api_g functions: 
\code{\link{plot_api_g_add_effect_times}()},
\code{\link{plot_api_g_create_aes}()}
}
\concept{plot_api_g functions}
