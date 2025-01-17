% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/correlation.regression.functions.R
\name{regressEns}
\alias{regressEns}
\title{Ensemble regression}
\usage{
regressEns(timeX, valuesX, timeY, valuesY, binvec = NA, binstep = NA,
  binfun = mean, max.ens = NA, percentiles = c(0.025, 0.25, 0.5, 0.75,
  0.975), recon.binvec = NA, minObs = 10)
}
\arguments{
\item{timeX}{matrix of age/time ensembles, or single column}

\item{valuesX}{matrix of values ensembles, or single column}

\item{timeY}{matrix of age/time ensembles, or single column}

\item{valuesY}{matrix of values ensembles, or single column}

\item{binvec}{vector of bin edges for binning step}

\item{binstep}{spacing of bins, used to build bin step}

\item{binfun}{function to use during binning (mean, sd, and sum all work)}

\item{max.ens}{maximum number of ensemble members to regress}

\item{percentiles}{quantiles to calculate for regression parameters}

\item{recon.binvec}{bin vector to use for the modeled regression.}

\item{minObs}{minimum number of points required to calculate regression}
}
\value{
list of ensemble output
}
\description{
This is the primary function for ensemble regression. It will take ensemble values in time and/or values in the predictor (X), and regress them on ensemble values in time and/or values in Y (the predictand). The function will then apply the ensemble linear model to the full length of X to create a modeled Y. Will also optionally create plots.
}
\seealso{
Other regress: \code{\link{plotRegressEns}},
  \code{\link{plotScatterEns}},
  \code{\link{plotTrendLinesEns}}
}
\author{
Nick McKay
}
