% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/bacon.lipd.R
\name{sampleBaconAges}
\alias{sampleBaconAges}
\title{Sample ensemble ages from Bacon}
\usage{
sampleBaconAges(corename, K = NA, baconDir = NA, maxEns = NA)
}
\arguments{
\item{corename}{the name used for the bacon model (and directories)}

\item{K}{the number of intervals over which the model is run, this is appended onto all the Bacon files after the underscore. If NA, will attempt to deduce from the directory.}

\item{baconDir}{the directory where Bacon is installed on this computer. Willimport if bossible.}

\item{maxEns}{the maximum number of ensemble members to import}
}
\value{
An ensemble table in the LiPD structure
}
\description{
Pulls ensemble members from Bacon output. Will be run in interactive mode if necessary parameters aren't specified. Most users will want to use runBacon for their bacon needs.
}
\examples{
ensTable = sampleBaconAges("MSB2K",maxEns = 1000)

}
\seealso{
Other Bacon: \code{\link{loadBaconOutput}},
  \code{\link{runBacon}}, \code{\link{writeBacon}}
}
\author{
Simon Goring

Nick McKay
}
