% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/correlation.regression.functions.R
\name{corrIsopersist}
\alias{corrIsopersist}
\title{Correlations and their significance according to AR(1) benchmarks}
\usage{
corrIsopersist(X, Y, alpha = 0.05, nsim = 100)
}
\arguments{
\item{X}{a 1-column vector}

\item{Y}{a 1-column vector of the same}

\item{alpha}{level of the test (probability of a type I error)}

\item{nsim}{number of simulations}
}
\value{
output
}
\description{
Fits AR(1) model to two series X & Y
}
\author{
Julien Emile-Geay
}
