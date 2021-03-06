# A dataframe with information about any of the compressibility correlation available
z_correlations <- data.frame(
    short = c("BB", "HY", "DAK", "DPR", "SH", "N10"),
    long = c("Beggs-Brill", "Hall-Yarborough", "Dranchuk-AbuKassem",
             "Dranchuk-Purvis-Robinson", "Shell", "Ann10"),
    function_name = c("z.BeggsBrill", "z.HallYarborough", "z.DranchukAbuKassem",
                      "z.DranchukPurvisRobinson", "z.Shell", "z.Ann10"),
    stringsAsFactors = FALSE
)


#' split a long string to create a vector for testing
#'
#' @param str a contnuous long string to split as a vector
#' @export
#' @examples
#' convertStringToVector("1.05 1.10 1.20")
#' # result: "c(1.05, 1.1, 1.2)"
#' # now, you can paste the vector in your test
convertStringToVector <- function(str) {
    vs <- unlist(strsplit(str, " "))
    vn <- as.numeric(vs)
    vt <- paste(vn, collapse = ", ")
    paste0('c(', vt, ')')
}


matrixToDataframe <- function(mat) {
    # convert a Ppr/Tpr matrix do a dataframe
    mat <- cbind(as.double(rownames(mat)), mat)  # new column for Tpr
    rownames(mat) <- NULL           # reset row names
    df <- as.data.frame(mat)        # dataframe
    names(df)[1] <- "Tpr"
    df
}


matrixWithCorrelation <- function(ppr_vector, tpr_vector, corr.Function) {
    # create a matrix using a z-factor correlation function and sapply
    co <- sapply(ppr_vector, function(x)
        sapply(tpr_vector, function(y) corr.Function(pres.pr = x, temp.pr = y)))

    if (length(ppr_vector) > 1 || length(tpr_vector) > 1) {
        co <- matrix(co, nrow = length(tpr_vector), ncol = length(ppr_vector))
        rownames(co) <- tpr_vector
        colnames(co) <- ppr_vector
    }
    co
}


combineCorrWithSK <- function(sk_df, co_df) {
    # combine correlation tidy DF with Standing-Katz tidy DF
    sk_tidy <- tidyr::gather(sk_df, "ppr", "z.chart", 2:ncol(sk_df))
    co_tidy <- tidyr::gather(co_df, "ppr", "z.calcs", 2:ncol(co_df))

    sk_co_tidy <- cbind(sk_tidy, z.calc = co_tidy$z.calcs)
    sk_co_tidy$dif <- sk_co_tidy$z.chart  - sk_co_tidy$z.calc
    colnames(sk_co_tidy)[1:2] <- c("Tpr", "Ppr")
    sk_co_tidy$Tpr <- as.character(sk_co_tidy$Tpr)
    sk_co_tidy$Ppr <- as.numeric(sk_co_tidy$Ppr)
    sk_co_tidy
}


#' Create a tidy table from Ppr and Tpr vectors
#'
#' @param ppr_vector a pseudo-reduced pressure vector
#' @param tpr_vector a pseudo-reduced temperature vector
#' @param correlation a z-factor correlation
#' @export
#' @examples
#' ppr <- c(0.5, 1.5, 2.5, 3.5)
#' tpr <- c(1.05, 1.1, 1.2)
#' createTidyFromMatrix(ppr, tpr, correlation = "DAK")
#' createTidyFromMatrix(ppr, tpr, correlation = "BB")
createTidyFromMatrix <- function(ppr_vector, tpr_vector, correlation) {
    isMissing_correlation(correlation)
    if (!isValid_correlation(correlation)) stop("Not a valid correlation.")

    zFunction <- get(z_correlations[which(z_correlations["short"] == correlation),
                                    "function_name"])

    sk_matrix <- getStandingKatzMatrix(ppr_vector, tpr_vector,
                                       pprRange = "lp")
    co_matrix <- matrixWithCorrelation(ppr_vector, tpr_vector,
                                       corr.Function = zFunction)

    sk_df <- matrixToDataframe(sk_matrix)
    co_df <- matrixToDataframe(co_matrix)

    sk_co_tidy <- combineCorrWithSK(sk_df, co_df)
    sk_co_tidy
}


isMissing_correlation <- function(correlation) {
    # stops if correlation argument is missing
    msg_missing <- paste("You have to provide a z-factor correlation: ",
                         paste(get_z_correlations(), collapse = " "))
    if (missing(correlation)) stop(msg_missing)
    else NULL
}


#' Check if supplied correlation (three letter) is valid
#'
#' @param correlation a z-factor correlation
#' @export
isValid_correlation <- function(correlation) {
    # check if supplied correlation is valid
    valid_choices <- z_correlations[["short"]]      # get vector of correlations
    ifelse(correlation %in% valid_choices, TRUE, FALSE)
}


#' Get correlation information
#'
#' @param how short: abbreviations; long: description; function: the name of the
#' correlation function
#' @export
#' @rdname get_z_correlations
#' @examples
#' # get the short name for the correlation
#' get_z_correlations(how = "short")
#'
#' # get the description for the correlation
#' get_z_correlations(how = "long")
#'
#' # get the name of the function assgined to the correlation
#' get_z_correlations(how = "function")
get_z_correlations <- function(how = "short") {
    # get correlation information. short: abbreviations; long: description
    #     function: the name of the correlation function
    if (how == "short")
        return(z_correlations[["short"]])
    if (how == "long")
        return(z_correlations[["long"]])
    if (how == "function")
        return(z_correlations[["function_name"]])
    else stop("wrong keyword")
}



#' Plot multiple Tpr curves in one figure
#'
#' Plot will show the digitized isotherm of the Standing-Katz chart
#'
#' @param tpr Pseudo-reduced temperature curve in SK chart
#' @param pprRange Takes one of two values: "lp": low pressure, or "hp" for
#' @param ... additional parameters
#' @rdname multiplotStandingKatz
#' @importFrom ggplot2 ggplot aes geom_line geom_point
#' @export
#' @examples
#' # plot Standing-Katz curves for Tpr=1.1 and 2.0
#' multiplotStandingKatz(c(1.1, 2))
#'
#' # plot SK curves for the lowest range of Tpr
#' multiplotStandingKatz(c(1.05, 1.1, 1.2))
multiplotStandingKatz <- function(tpr, pprRange = "lp", ...) {
    Ppr <- NULL; z <- NULL; Tpr <- NULL
    tpr_li <- getStandingKatzData(tpr, pprRange = pprRange)

    # join the dataframes with rbindlist adding an identifier column
    tpr_df <- data.table::rbindlist(tpr_li, idcol = TRUE)
    colnames(tpr_df)[1] <- "Tpr"    # name the identifier as Tpr

    g <- ggplot(tpr_df, aes(x=Ppr, y=z, group=Tpr, color=Tpr)) +
        geom_line() +
        geom_point()
    print(g)
}