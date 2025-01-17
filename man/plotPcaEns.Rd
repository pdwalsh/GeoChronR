% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotting.geoChronR.R
\name{plotPcaEns}
\alias{plotPcaEns}
\title{Map ensemble pca loadings and plot PC timeseries}
\usage{
plotPcaEns(ens.PC.out, TS, map.type = "line", which.PCs = c(1, 2),
  f = 0.2, color = "temp", dotsize = 5, restrict.map.range = TRUE,
  shape.by.archive = TRUE, projection = "mollweide", boundcirc = TRUE,
  probs = c(0.025, 0.25, 0.5, 0.75, 0.975), which.leg = 1,
  legendPosition = c(0.5, 0.5))
}
\arguments{
\item{ens.PC.out}{results of pcaEns()}

\item{TS}{Timeseries object \url{http://nickmckay.github.io/LiPD-utilities/r/index.html#what-is-a-time-series} used in the pcaEns() analysis}

\item{map.type}{"google" or "line"}

\item{which.PCs}{vector of PCs to plot. Choose two. c(1,2) is default.}

\item{f}{zoom buffer for plotting}

\item{color}{color scale option. See assignColors()}

\item{dotsize}{How big are the dots on the map}

\item{restrict.map.range}{TRUE or FALSE. Trim the size of the map to the points, for "line" map type}

\item{shape.by.archive}{TRUE or FALSE. Use archiveType to assign shapes.}

\item{projection}{Map project. All options on: ?mapproject}

\item{boundcirc}{For polar projects, draw a boundary circle? TRUE or FALSE}

\item{probs}{quantiles to calculate and plot in the PC timeseries}

\item{which.leg}{which map legend to include in the summary plot?}

\item{legendPosition}{Where to put the map legend?}

\item{lineLabels}{Labels for the quantiles lines}
}
\value{
A gridExtra ggplot object
}
\description{
Map ensemble pca loadings and plot PC timeseries
}
\seealso{
Other plot: \code{\link{AD2BP_trans}},
  \code{\link{BP2AD_trans}}, \code{\link{PeriodAnnotate}},
  \code{\link{axisLabel}},
  \code{\link{geoChronRPlotTheme}},
  \code{\link{getLegend}}, \code{\link{getPlotRanges}},
  \code{\link{plotChronEnsDiff}},
  \code{\link{plotChronEns}}, \code{\link{plotChron}},
  \code{\link{plotCorEns}}, \code{\link{plotHistEns}},
  \code{\link{plotLine}},
  \code{\link{plotModelDistributions}},
  \code{\link{plotPvalsEnsFdr}},
  \code{\link{plotRegressEns}},
  \code{\link{plotScatterEns}},
  \code{\link{plotSpectraEns}}, \code{\link{plotSpectrum}},
  \code{\link{plotSummary}},
  \code{\link{plotTimeseriesEnsLines}},
  \code{\link{plotTimeseriesEnsRibbons}},
  \code{\link{plotTimeseriesStack}},
  \code{\link{plotTrendLinesEns}},
  \code{\link{reverselog10_trans}}

Other pca: \code{\link{ar1Surrogates}},
  \code{\link{createSyntheticTimeseries}},
  \code{\link{getLegend}}, \code{\link{pcaEns}}
}
\author{
Nick McKay
}
