% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/lgpr.R
\name{lgp}
\alias{lgp}
\title{Main function of the lgpr package}
\usage{
lgp(
  formula,
  data,
  likelihood = "gaussian",
  prior = NULL,
  c_hat = NULL,
  num_trials = NULL,
  options = NULL,
  prior_only = FALSE,
  verbose = FALSE,
  sample_f = !(likelihood == "gaussian"),
  ...
)
}
\arguments{
\item{formula}{The model formula, where
\itemize{
  \item it must contain exatly one tilde (\code{~}), with response
  variable on the left-hand side and model terms on the right-hand side
  \item terms are be separated by a plus (\code{+}) sign
  \item all variables appearing in \code{formula} must be
  found in \code{data}
}
See the "Model formula syntax" section below (\code{\link{lgp}}) for
instructions on how to specify the model terms.}

\item{data}{A \code{data.frame} where each column corresponds to one
variable, and each row is one observation. Continuous covariates and the
response variable must have type \code{"numeric"} and categorical covariates
must have type \code{"factor"}. Missing values should be indicated with
\code{NaN} or \code{NA}. The response variable cannot contain missing
values. Column names should not contain trailing or leading underscores.}

\item{likelihood}{Determines the observation model. Must be either
\code{"gaussian"} (default), \code{"poisson"}, \code{"nb"} (negative
binomial), \code{"binomial"} or \code{"bb"} (beta binomial).}

\item{prior}{A named list, defining the prior distribution of model
(hyper)parameters. See the "Defining priors" section below
(\code{\link{lgp}}).}

\item{c_hat}{The GP mean. Must be a vector of length \code{dim(data)[1]}, or
a real number defining a constant GP mean. If not specified, this is set to
 \itemize{
   \item \code{c_hat = 0}, if \code{likelihood} is \code{"gaussian"},
   \item \code{c_hat = } \code{log(mean(y))} if \code{likelihood} is
   \code{"poisson"} or \code{"nb"},
   \item \code{c_hat = } \code{log(p/(1-p))}, where
   \code{p = mean(y/num_trials)} if \code{likelihood} is \code{"binomial"}
   or \code{"bb"},
 }
where \code{y} denotes the response variable.}

\item{num_trials}{This argument (number of trials) is only needed when
likelihood is \code{"binomial"} or \code{"bb"}. Must have length one or
equal to the number of data points. Setting \code{num_trials=1} and
\code{likelihood="binomial"} corresponds to Bernoulli observation model.}

\item{options}{A named list with the following possible fields:
\itemize{
  \item \code{delta} Amount of added jitter to ensure positive definite
  covariance matrices.
  \item \code{do_yrng} Should random numbers be drawn from the predictive
  distribution (one for each posterior draw). This can be set to true
  in order to do prior or posterior predictive sampling, and only has
  any effect if \code{sample_f = TRUE}.
}
If \code{options} is \code{NULL}, default options are used. The defaults
are equivalent to \code{options = list(delta = 1e-8, do_yrng = FALSE)}.}

\item{prior_only}{Should sampling be done in prior mode,
where likelihood is ignored? This can be used to do prior predictive
sampling, with \code{options = list(do_yrng = TRUE)} and
\code{sample_f = TRUE}.}

\item{verbose}{Should more verbose output be printed?}

\item{sample_f}{Determines if the latent function values are be sampled
(must be \code{TRUE} if likelihood is not \code{"gaussian"}). If this is
\code{TRUE}, the response variable will be normalized to have zero mean
and unit variance.}

\item{...}{Optional arguments passed to
\code{\link[rstan]{sampling}} or \code{\link[rstan]{optimizing}}.}
}
\value{
Returns an object of the S4 class \linkS4class{lgpfit}.
}
\description{
Creates a model by calling \code{\link{create_model}} and fits by calling
\code{\link{sample_model}}.
}
\section{Model formula syntax}{

There are two ways to define the model formula:
\enumerate{
  \item Using a common \code{\link[stats]{formula}}-like syntax, like in
  \code{y ~ age +} \code{age|id} \code{ + sex}. Terms can consist of a
  single variable, such as \code{age}, or an interaction of two variables,
  such as \code{age|id}. In single-variable terms, the variable can be either
  continuous (numeric) or categorical (factor), whereas in interaction terms
  the variable on the left-hand side of the vertical bar (\code{|}) has to
  be continuous and the one on the right-hand side has to be categorical.
  Formulae specified using this syntax are translated to the advanced format
  so that
  \itemize{
    \item single-variable terms become \code{gp(x)} if
    variable \code{x} is numeric and \code{zs(x)} if \code{x} is a factor
    \item interaction terms \code{x|z} become \code{gp(x)*zs(z)}
  }
  \item Using the advanced syntax, like in \code{y ~ gp(age) +}
  \code{gp(age)*zs(id) +} \code{het(id)*gp_vm(disAge)}.
  This creates \linkS4class{lgprhs} objects, which consist of
 \linkS4class{lgpterm}s, which consist of \linkS4class{lgpexpr}s.
 This approach must be used if creating nonstationary, heterogeneous or
 temporally uncertain components.
}
Either one of the approaches should be used and they should not be mixed.
}

\section{Defining priors}{

The \code{prior} argument must be a named list, like
\code{list(alpha=student_t(4), wrp=igam(30,10))}. See examples in tutorials.
Possible allowed names are
\itemize{
 \item \code{"alpha"} = component magnitude parameters
 \item \code{"ell"} = component lengthscale parameters
 \item \code{"wrp"} = input warping steepness parameters
 \item \code{"sigma"} = noise magnitude (Gaussian obs. model)
 \item \code{"phi"} = inv. overdispersion (negative binomial obs. model)
 \item \code{"gamma"} = overdispersion (beta-binomial obs. model)
 \item \code{"beta"} = heterogeneity parameters
 \item \code{"effect_time"} = uncertain effect time parameters
 \item \code{"effect_time_info"} = additional options for the above
}
See \code{\link{priors}} for functions that can be
used to define the list elements. If a parameter of a model is not given
in this list, a default prior will be used for it.
}

\section{When to not use default priors}{


It is not recommended to use default priors blindly. Rather, priors should
be specified according to the knowledge about the problem at hand, as in any
Bayesian analysis. In \code{lgpr} this is especially important when
\enumerate{
 \item Using a non-Gaussian likelihood or otherwise setting
 \code{sample_f = TRUE}. In this case the response variable is not
 normalized, so the scale on which the data varies must be taken into
 account when defining priors of the signal magnitude parameters
 \code{alpha} and possible noise parameters (\code{sigma}, \code{phi},
 \code{gamma}). Also it should be checked if \code{c_hat} is set in a
 sensible way.
 \item Using a model that contains a \code{gp_ns(x)} or \code{gp_vm(x)}
 expression in its formula. In this case the corresponding covariate
 \code{x} is not normalized, and the prior for the input warping steepness
 parameter \code{wrp} must be set according to the expected width of the
 window in which the nonstationary effect of \code{x} occurs. By default,
 the width of this window is about 36, which has been set assuming that
 the unit of \code{x} is months.
}
}

\seealso{
Other main functions: 
\code{\link{create_model}()},
\code{\link{sample_model}()}
}
\concept{main functions}
