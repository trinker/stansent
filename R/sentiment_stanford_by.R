#' Polarity Score (Sentiment Analysis) By Groups
#'
#' Approximate the sentiment (polarity) of text by grouping variable(s).
#'
#' @param text.var The text variable.
#' @param by The grouping variable(s).  Default \code{NULL} uses the original
#' row/element indices; if you used a column of 12 rows for \code{text.var}
#' these 12 rows will be used as the grouping variable.  Also takes a single
#' grouping variable or a list of 1 or more grouping variables.
#' @param averaging.function A function for performing the group by averaging.
#' The default, \code{\link[sentimentr]{average_downweighted_zero}}, downweights
#' zero values in the averaging.  Note that the function must handle
#' \code{NA}s.  The \pkg{sentimentr} functions
#' \code{average_weighted_mixed_sentiment} and \code{average_mean} are also
#' available.  The former upweights negative when the analysts suspects the
#' speaker is likely to surround negatives with positives (mixed) as a polite
#' social convention but still the affective state is negative.  The later is a
#' standard mean average.
#' @param group.names A vector of names that corresponds to group.  Generally
#' for internal use.
#' @param \ldots Other arguments passed to \code{\link[stansent]{sentiment_stanford}}.
#' @details Note that the coreNLP is expensive with regard to time.  Typically it is
#' better to use \code{sentiment_stanford} and do the merging and aggregation/summarization
#' yourself.
#' @return Returns a \pkg{data.table} with grouping variables plus:
#' \itemize{
#'   \item  element_id - The id number of the original vector passed to \code{sentiment}
#'   \item  sentence_id - The id number of the sentences within each \code{element_id}
#'   \item  word_count - Word count \code{\link[base]{sum}}med by grouping variable
#'   \item  sd - Standard deviation (\code{\link[stats]{sd}}) of the sentiment/polarity score by grouping variable
#'   \item  ave_sentiment - Sentiment/polarity score \code{\link[base]{mean}} average by grouping variable
#' }
#' @keywords sentiment, polarity, group
#' @export
#' @family sentiment functions
#' @examples
#' \dontrun{
#' mytext <- c(
#'    'do you like it?  But I hate really bad dogs',
#'    'I am the best friend.',
#'    'Do you really like it?  I\'m not happy'
#' )
#' x <- sentiment_stanford(mytext)
#'
#' y <- sentiment_stanford_by(mytext)
#' sentiment_stanford_by(y)
#' sentiment_stanford_by(x)
#' get_sentences(sentiment_stanford_by(x))
#'
#' (mysentiment <- sentiment_stanford_by(x))
#' stats::setNames(get_sentences(sentiment_stanford_by(x)),
#'     round(mysentiment[["ave_sentiment"]], 3))
#'
#' library(sentimentr)
#' (out1 <- with(presidential_debates_2012, sentiment_stanford_by(dialogue, person)))
#' (out2 <- with(presidential_debates_2012, sentiment_stanford_by(out1, list(person, time))))
#' plot(out1)
#' plot(out2)
#' plot(out2, 10)
#' plot(uncombine(out2))
#'
#' ## Hilighting
#' highlight(
#'     with(
#'         sentimentr::cannon_reviews,
#'         sentiment_stanford_by(review, number)
#'     )
#' )
#' }
sentiment_stanford_by  <- function(text.var, by = NULL,
    averaging.function = stansent::average_downweighted_zero, group.names, ...){

    UseMethod("sentiment_stanford_by")
}

#' @export
#' @method sentiment_stanford_by character
sentiment_stanford_by.character <- function(text.var, by = NULL,
    averaging.function = stansent::average_downweighted_zero, group.names, ...){

    word_count <- ave_sentiment <- NULL
    if (methods::is(text.var, "sentiment_by")){
        out <- attributes(text.var)[["sentiment"]][["sentiment"]]
    } else {
        if (methods::is(text.var, "sentiment")){
            out <- text.var
        } else {
            out <- sentiment_stanford(text.var = gsub('\\s+', ' ', text.var), ...)
        }
    }

    if (is.null(by)){
        out2 <- out[, list('word_count' = sum(word_count, na.rm = TRUE),
        	  'sd' = stats::sd(sentiment, na.rm = TRUE),
        	  'ave_sentiment' = mean(sentiment, na.rm = TRUE)), by = "element_id"]
        G <- "element_id"
        uncombined <- out
    } else {
        if (is.list(by) & length(by) > 1) {
            m <- unlist(as.character(substitute(by))[-1])
            G <- sapply(strsplit(m, "$", fixed=TRUE), function(x) {
                    x[length(x)]
                }
            )
            grouping <- by
        } else {
            G <- as.character(substitute(by))
            G <- G[length(G)]
            grouping <- unlist(by)
        }

        if(!missing(group.names)) {
            G <- group.names
        }


        group_dat <- stats::setNames(as.data.frame(grouping,
            stringsAsFactors = FALSE), G)

        data.table::setDT(group_dat)
        group_dat <- group_dat[out[["element_id"]], ]

        uncombined <- out2 <- cbind(group_dat, out)

        out2 <- out2[, list('word_count' = sum(word_count, na.rm = TRUE),
            'sd' = stats::sd(sentiment, na.rm = TRUE),
            'ave_sentiment' = averaging.function(sentiment)), keyby = G][order(-ave_sentiment)]

    }

    class(out2) <- unique(c("sentiment_stanford_by", "sentiment_by", class(out)))
    sentiment <- new.env(FALSE)
    sentiment[["sentiment"]] <- out
    attributes(out2)[["sentiment"]] <- sentiment
    attributes(out2)[["groups"]] <- G

    uncombine <- new.env(FALSE)
    uncombine[["uncombine"]] <- uncombined
    attributes(out2)[["uncombine"]] <- uncombine
    out2

}



#' @export
#' @method sentiment_stanford_by sentiment_by
sentiment_stanford_by.sentiment_by <- function(text.var, by = NULL,
    averaging.function = average_downweighted_zero, group.names, ...){

	word_count <- ave_sentiment <- NULL
    out <- attributes(text.var)[['sentiment']][['sentiment']]

    if (is.null(by)){
        out2 <- out[, list('word_count' = sum(word_count, na.rm = TRUE),
        	  'sd' = stats::sd(sentiment, na.rm = TRUE),
        	  'ave_sentiment' = averaging.function(sentiment)), by = "element_id"]
        G <- "element_id"
        uncombined <- out
    } else {
        if (is.list(by) & length(by) > 1) {
            m <- unlist(as.character(substitute(by))[-1])
            G <- sapply(strsplit(m, "$", fixed=TRUE), function(x) {
                    x[length(x)]
                }
            )
            grouping <- by
        } else {
            G <- as.character(substitute(by))
            G <- G[length(G)]
            grouping <- unlist(by)
        }

        if(!missing(group.names)) {
            G <- group.names
        }


        group_dat <- stats::setNames(as.data.frame(grouping,
            stringsAsFactors = FALSE), G)

        data.table::setDT(group_dat)
        group_dat <- group_dat[out[["element_id"]], ]

        uncombined <- out2 <- cbind(group_dat, out)

        out2 <- out2[, list('word_count' = sum(word_count, na.rm = TRUE),
            'sd' = stats::sd(sentiment, na.rm = TRUE),
            'ave_sentiment' = averaging.function(sentiment)), keyby = G]#[order(-ave_sentiment)]

    }

    class(out2) <- unique(c("sentiment_stanford_by", "sentiment_by", class(out)))
    sentiment <- new.env(FALSE)
    sentiment[["sentiment"]] <- out
    attributes(out2)[["sentiment"]] <- sentiment
    attributes(out2)[["groups"]] <- G

    uncombine <- new.env(FALSE)
    uncombine[["uncombine"]] <- uncombined
    attributes(out2)[["uncombine"]] <- uncombine
    out2

}


#' @export
#' @method sentiment_stanford_by sentiment
sentiment_stanford_by.sentiment <- function(text.var, by = NULL,
    averaging.function = average_downweighted_zero, group.names, ...){

	word_count <- ave_sentiment <- NULL
    out <- text.var

    if (is.null(by)){
        out2 <- out[, list('word_count' = sum(word_count, na.rm = TRUE),
        	  'sd' = stats::sd(sentiment, na.rm = TRUE),
        	  'ave_sentiment' = averaging.function(sentiment)), by = "element_id"]
        G <- "element_id"
        uncombined <- out
    } else {
        if (is.list(by) & length(by) > 1) {
            m <- unlist(as.character(substitute(by))[-1])
            G <- sapply(strsplit(m, "$", fixed=TRUE), function(x) {
                    x[length(x)]
                }
            )
            grouping <- by
        } else {
            G <- as.character(substitute(by))
            G <- G[length(G)]
            grouping <- unlist(by)
        }

        if(!missing(group.names)) {
            G <- group.names
        }


        group_dat <- stats::setNames(as.data.frame(grouping,
            stringsAsFactors = FALSE), G)

        data.table::setDT(group_dat)
        group_dat <- group_dat[out[["element_id"]], ]

        uncombined <- out2 <- cbind(group_dat, out)

        out2 <- out2[, list('word_count' = sum(word_count, na.rm = TRUE),
            'sd' = stats::sd(sentiment, na.rm = TRUE),
            'ave_sentiment' = averaging.function(sentiment)), keyby = G]#[order(-ave_sentiment)]

    }

    class(out2) <- unique(c("sentiment_stanford_by", "sentiment_by", class(out)))
    sentiment <- new.env(FALSE)
    sentiment[["sentiment"]] <- out
    attributes(out2)[["sentiment"]] <- sentiment
    attributes(out2)[["groups"]] <- G

    uncombine <- new.env(FALSE)
    uncombine[["uncombine"]] <- uncombined
    attributes(out2)[["uncombine"]] <- uncombine
    out2

}


#' Plots a sentiment_stanford_by object
#'
#' Plots a sentiment_stanford_by object.
#'
#' @param x The sentiment_stanford_by object.
#' @param max The maximum point size.
#' @param \ldots ignored
#' @method plot sentiment_stanford_by
#' @importFrom graphics plot
#' @return Returns a \pkg{ggplot2} object.
#' @export
plot.sentiment_stanford_by <- function(x, max = 20, ...){

    .N <- ave_sentiment <- grouping.vars <- NULL
    dat2 <- uncombine(x)

    grps <- attributes(x)[["groups"]]
    if (length(grps) == 1 && grps == "element_id") return(plot(dat2))

    x[, "grouping.vars"] <- paste2(x[, attributes(x)[["groups"]], with=FALSE])
    x[, grouping.vars := factor(grouping.vars, levels = rev(grouping.vars))]

    dat2[, "grouping.vars"] <- paste2(dat2[, attributes(x)[["groups"]], with=FALSE])
    dat2[, grouping.vars := factor(grouping.vars, levels = levels(x[["grouping.vars"]]))]

    x <- x[order(-ave_sentiment)]
    x[, grouping.vars := factor(grouping.vars, levels = rev(grouping.vars))]

    #center_dat <- dat2[, list(upper = mean(sentiment, na.rm = TRUE) + 2*SE(sentiment),
    #    lower = mean(sentiment, na.rm = TRUE) - 2*SE(sentiment),
    #    means = mean(sentiment, na.rm = TRUE)), keyby = "grouping.vars"]
    dat3 <- dat2[, list('n' = .N), by = c('grouping.vars', 'sentiment')]

    ggplot2::ggplot() +
        ggplot2::geom_hline(ggplot2::aes(yintercept=0), size = 1, color="grey80", linetype = 'dashed') +
        ggplot2::geom_point(data=x, ggplot2::aes_string(x = 'grouping.vars', y = 'ave_sentiment'), color="red", shape=3, size=4)  +
        #ggplot2::geom_boxplot(data=dat2, ggplot2::aes_string('grouping.vars', 'sentiment', color = "grouping.vars"),
        #    alpha=.1, fill =NA, size = 1, outlier.size = 0, coef = 0) +
        ggplot2::geom_point(data=dat3, ggplot2::aes_string(y = 'sentiment',
            x = 'grouping.vars', size = 'n'), alpha=.1) +
        ggplot2::coord_flip() +
        ggplot2::theme_bw() +
        ggplot2::guides(color=FALSE) +
        ggplot2::scale_y_continuous(limits = c(-1, 1), breaks=seq(-1, 1, by = .5)) +
        ggplot2::ylab("Sentiment") +
        ggplot2::xlab("Groups") +
        ggplot2::theme(panel.grid = ggplot2::element_blank()) +
        ggplot2::scale_size(range = c(3, max))

}

