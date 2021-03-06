% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils.R
\name{multiplotStandingKatz}
\alias{multiplotStandingKatz}
\title{Plot multiple Tpr curves in one figure}
\usage{
multiplotStandingKatz(tpr, pprRange = "lp", ...)
}
\arguments{
\item{tpr}{Pseudo-reduced temperature curve in SK chart}

\item{pprRange}{Takes one of two values: "lp": low pressure, or "hp" for}

\item{...}{additional parameters}
}
\description{
Plot will show the digitized isotherm of the Standing-Katz chart
}
\examples{
# plot Standing-Katz curves for Tpr=1.1 and 2.0
multiplotStandingKatz(c(1.1, 2))

# plot SK curves for the lowest range of Tpr
multiplotStandingKatz(c(1.05, 1.1, 1.2))
}
