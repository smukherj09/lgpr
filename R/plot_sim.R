#' Visualize an lgpsim object (simulated data)
#'
#' @param simdata an object of class \linkS4class{lgpsim}
#' @param h_name name of the signal in \code{simdata$components}
#' @param x_name name of x-axis variable
#' @param y_name name of response variable
#' @param group_by grouping factor
#' @param color_by coloring factor
#' @param verbose should some information be printed?
#' @param ... additional arguments to \code{\link{plot_api_g}} or
#' \code{\link{plot_api_c}}
#' @param comp_idx Possible index of a component to be shown.
#' If this is NULL, the data and total signal are shown.
#' @return a \code{\link[ggplot2]{ggplot}} object
#' @family main plot functions
#' @name plot_sim
NULL

#' @export
#' @rdname plot_sim
plot_sim <- function(simdata,
                     group_by = "id",
                     x_name = "age",
                     h_name = "h",
                     y_name = "y",
                     comp_idx = NULL,
                     color_by = NA,
                     verbose = TRUE,
                     ...) {
  if (is.null(comp_idx)) {
    p <- plot_sim.data(simdata, group_by, x_name, h_name, y_name, verbose, ...)
    return(p)
  }
  plot_sim.component(
    simdata, comp_idx, group_by, x_name, color_by, verbose, ...
  )
}

#' @rdname plot_sim
plot_sim.data <- function(simdata,
                          group_by,
                          x_name,
                          h_name,
                          y_name,
                          verbose,
                          ...) {
  check_type(simdata, "lgpsim")
  data <- simdata@data
  df_points <- data[c(group_by, x_name, y_name)]
  df_lines <- data[c(group_by, x_name)]
  df_lines$y <- simdata@components[[h_name]]

  teff_true <- dollar(simdata@effect_times, "true")
  teff_true <- null_if_all_nan(teff_true)
  teff_obs <- dollar(simdata@effect_times, "observed")
  teff_obs <- null_if_all_nan(teff_obs)
  h <- plot_api_g(
    df_data = df_points,
    df_signal = df_lines,
    teff_signal = teff_true,
    teff_obs = teff_obs,
    ...
  )
  noise_type <- dollar(simdata@info, "noise_type")
  info <- plot_sim.data.title(noise_type)
  if (!is.null(teff_true)) {
    info <- paste(info, plot_sim.data.title_teff(), sep = "\n")
  }
  if (verbose) cat(info, "\n")
  h <- h + ggplot2::ggtitle("Simulated data")
  return(h)
}

#' @rdname plot_sim
plot_sim.component <- function(simdata,
                               comp_idx,
                               group_by,
                               x_name,
                               color_by,
                               verbose,
                               ...) {
  check_type(simdata, "lgpsim")
  check_not_null(comp_idx)
  out <- plot_sim.component.df(
    simdata, x_name, group_by, color_by,
    comp_idx
  )
  title <- dollar(out, "name")
  h <- plot_api_c(df = dollar(out, "df"), ...)
  h <- h + ggplot2::ylab("f") + ggplot2::ggtitle(title)
  if (verbose) cat("Plotting component", comp_idx, "\n")
  return(h)
}

#' @rdname plot_sim
plot_sim.component.df <- function(simdata, x_name, group_by, color_by,
                                  comp_idx) {
  data <- simdata@data
  df_comp <- get_sim_components(simdata)
  J <- ncol(df_comp)
  check_interval(comp_idx, 1, J)
  f <- as.vector(df_comp[, comp_idx])
  name <- colnames(df_comp)[comp_idx]
  group <- dollar(data, group_by)
  if (is.na(color_by)) {
    color <- as.factor(rep(1, nrow(data)))
  } else {
    color <- dollar(data, color_by)
    if (!is.factor(color)) {
      # Color by whether or not the coloring variable is NA or NaN
      color <- as.numeric(!is.na(color))
      color <- as.factor(c("N/A", "available")[color + 1])
    }
  }
  x <- dollar(data, x_name)
  df <- data.frame(group, x, color, f)
  colnames(df) <- c(group_by, x_name, color_by, "y")
  list(df = df, name = name)
}


#' Helpers for plot_sim.data
#'
#' @param noise_type noise type name
#' @name plot_sim_data_title
NULL

#' @rdname plot_sim_data_title
plot_sim.data.title <- function(noise_type) {
  info1 <- "- Dots are noisy observations of the response var."
  info2 <- "- Line is the true signal mapped through inv. link fun."
  info3 <- "  (and multiplied by number of trials)"
  info <- paste(info1, info2, sep = "\n")
  is_bin <- is_bin_or_bb(noise_type)
  if (is_bin) info <- paste(info, info3, sep = "\n")
  return(info)
}

#' @rdname plot_sim_data_title
plot_sim.data.title_teff <- function() {
  paste0(
    "- Solid vert. line is the real effect time (used to generate ",
    "signal) \n- Dashed vert. line is the 'observed' disease ",
    "initiation time"
  )
}
