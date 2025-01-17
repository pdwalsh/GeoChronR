% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotting.geoChronR.R
\name{bin2d}
\alias{bin2d}
\title{Two dimensional binning}
\usage{
bin2d(x, y, nbins = 100, x.bin = NA, y.bin = NA, filterFrac = NA,
  interpolate = TRUE)
}
\arguments{
\item{x}{n by m matrix where n is the number of observations and m is >= 1}

\item{y}{n by j matrix where n is the number of observations and j is >= 1}

\item{nbins}{number bins over which to calculate intervals. Used to calculate x.bin if not provided.}

\item{x.bin}{vector of bin edges over which to bin.}

\item{y.bin}{vector of bin edges over which to bin.}

\item{filterFrac}{Used to beef up sampling for poorly sampled intervals. Interpolates intervals with less than filterFrac coverage.}

\item{interpolate}{use interpolation? T/F}
}
\value{
A list with a matrix of density, x.bin and y.bin
}
\description{
Calculate the density of samples along a 2-dimensional grid
}
\seealso{
Other gridding: \code{\link{kde_2d}},
  \code{\link{quantile2d}}
}
