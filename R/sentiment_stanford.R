#' Wrappper to Standford's coreNLP Sentiment Tagger
#'
#' Tag sentiment as most negative (-1) to most positive (+1).  A
#' reimplementation of Matthew Jocker's Stanford coreNLP wrapper in \pkg{syuzhet}.
#'
#' @param text.var The text variable.
#' @param stanford.tagger path to the Stanford tagger.
#' @param hyphen The character string to replace hyphens with.  Default replaces
#' with nothing so 'sugar-free' becomes 'sugarfree'.  Setting \code{hyphen = " "}
#' would result in a space between words (e.g., 'sugar free').
#' @param missing_value A value to replace \code{NA}/\code{NaN} with.  Use
#' \code{NULL} to retain missing values.
#' @param java.path Path to where \pkg{Java} resides.  If  \pkg{Java} is on your
#' path the minimal \code{java.path = "java"} is all that should be required.
#' @param \ldots Other arguments passed to \code{check_stanford_installed}.
#' @return Returns a \pkg{data.table} of:
#' \itemize{
#'   \item  element_id - The id number of the original vector passed to \code{sentiment}
#'   \item  sentence_id - The id number of the sentences within each \code{element_id}
#'   \item  word_count - Word count
#'   \item  sentiment - Sentiment/polarity score
#' }
#' @references http://nlp.stanford.edu/software/corenlp.shtml \cr
#' \url{http://www.matthewjockers.net/2015/03/04/some-thoughts-on-annies-thoughts-about-syuzhet}
#' @keywords sentiment
#' @export
#' @examples
#' \dontrun{
#' mytext <- c(
#'    'do you like it?  But I hate really bad dogs',
#'    'I am the best friend.',
#'    'Do you really like it?  I\'m not a fan'
#' )
#' sentiment_stanford(mytext)
#'
#' library(sentimentr)
#' data(sam_i_am)
#' (sam <- sentiment_stanford(gsub("Sam-I-am", "Sam I am", sam_i_am)))
#' plot(sam)
#' plot(sam, scale_range = TRUE, low_pass_size = 5)
#' plot(sam, scale_range = TRUE, low_pass_size = 10)
#' y <- "He was not the sort of man that one would describe as especially handsome."
#' sentiment_stanford(y)
#'
#' if (!require("pacman")) install.packages("pacman")
#' pacman::p_load_gh("trinker/textshape", "trinker/sentimentr")
#' pacman::p_load(syuzhet)
#'
#' temp <- tempdir()
#' pang_et_al <- "http://www.cs.cornell.edu/people/pabo/movie-review-data/review_polarity.tar.gz"
#' download.file(pang_et_al, file.path(temp, basename(pang_et_al)))
#'
#' untar(file.path(temp, basename(pang_et_al)), exdir = file.path(temp, "out"))
#' dirs <- sprintf(file.path(temp, "out/txt_sentoken/%s"), c("neg", "pos"))
#' text_vector <- paste(unlist(lapply(
#'     c(file.path(dirs[1], dir(dirs[1])[1]),
#'         file.path(dirs[2], dir(dirs[2])[1])
#'     ),  readLines)), collapse = " ")
#'
#' sents <- textshape::split_sentence(text_vector)[[1]]
#'
#' syuzhet <- setNames(as.data.frame(lapply(c("bing", "afinn", "nrc"),
#'     function(x) syuzhet::get_sentiment(sents[[1]], method=x))), c("bing", "afinn", "nrc"))
#'
#' width <- options()$width
#' options(width=1000)
#'
#' left_just(data.frame(
#'     stanford = round(sentiment_stanford(sents)[["sentiment"]], 2),
#'     sentimentr = round(sentiment(sents, question.weight = 0)[["sentiment"]], 2),
#'     syuzhet,
#'     sentences = unlist(sents),
#'     stringsAsFactors = FALSE
#' ), "sentences")
#'
#' options(width=width)
#' }
sentiment_stanford <- function(text.var, hyphen = "", missing_value = 0,
    stanford.tagger = stansent::coreNLP_loc(), java.path = "java", ...){

    sentiment <- .N <- NULL

    # break rows into sentences, count words
    sents <- textshape::split_sentence(text.var)

    sent_dat <- data.frame(element_id = seq_along(sents))
    sent_dat[["sentences"]] <- sents
    data.table::setDT(sent_dat)

    sent_dat <- sent_dat[, list('sentences' = unlist(sentences)), by = 'element_id'][,
       'sentences' := punctuation_reducer(sentences, hyphen = hyphen)][,
       'sentence_id' := seq_len(.N), by='element_id'][,
       'word_count' := replace_zero(stringi::stri_count_words(sentences))][,
       'sentiment' := sentiment_stanford_helper(sentences,
           stanford.tagger = stanford.tagger, java.path = java.path, ...)]


    if (!is.null(missing_value)){
        sent_dat[, 'sentiment' := replace_na(sentiment, y = missing_value)]
    }

    sent_dat <- sent_dat[, c("element_id", "sentence_id", "word_count", "sentiment"), with = FALSE]

    class(sent_dat) <- unique(c("sentiment", class(sent_dat)))
    sentences <- new.env(FALSE)
    sentences[["sentences"]] <- sents
    attributes(sent_dat)[["sentences"]] <- sentences
    sent_dat[]
}

punctuation_reducer <- function(x, hyphen){
    x <- gsub("[.?!](?!$)", " ", gsub("(?<=[.?!])[.?!]+$", "",
        x, perl = TRUE), perl = TRUE)

    if (!is.null(hyphen)){
        x <- gsub("-", hyphen, x)
    }
    x
}

replace_na <- function(x, y = 0) {x[is.na(x)] <- y; x}
replace_zero <- function(x, y = NA) {x[x == 0] <- y; x}

#' Plots a sentiment object
#'
#' Plots a sentiment object.
#'
#' @param x The sentiment object.
#' @param \ldots Other arguments passed to \code{\link[syuzhet]{get_transformed_values}}.
#' @details Utilizes Matthew Jocker's \pkg{syuzhet} package to calculate smoothed
#' sentiment across the duration of the text.
#' @return Returns a \pkg{ggplot2} object.
#' @method plot sentiment
#' @export
plot.sentiment <- function(x, ...){

    m <- syuzhet::get_transformed_values(stats::na.omit(x[["sentiment"]]), ...)

    dat <- data.frame(
        Emotional_Valence = m,
        Duration = seq_along(m)
    )

    ggplot2::ggplot(dat, ggplot2::aes_string('Duration', 'Emotional_Valence')) +
        ggplot2::geom_path(size=1, color="blue") +
        ggplot2::theme_bw() +
        ggplot2::theme(plot.margin = grid::unit(c(5.1, 15.1, 4.1, 2.1), "pt")) +
        ggplot2::ylab("Emotional Valence") +
        ggplot2::theme(panel.grid = ggplot2::element_blank()) +
        ggplot2::scale_x_continuous(label=function(x) paste0(x, "%"),
            expand = c(0,0), limits = c(0,100))

}

sentiment_stanford_helper <- function (text.var,
    stanford.tagger = stansent::coreNLP_loc(), java.path = "java", ...) {

    if (!file.exists(stanford.tagger)) {
        check_stanford_installed(...)
    }

    #text.var <- gsub("[.?!](?!$)", " ", gsub("(?<=[.?!])[.?!]+$", "", text.var, perl = TRUE), perl = TRUE)

    #message("\nAnalyzing text for sentiment...\n")

    cmd <- sprintf(
        "%s -cp \"%s/*\" -mx5g edu.stanford.nlp.pipeline.StanfordCoreNLP -annotators \"tokenize,ssplit,parse,sentiment\" -ssplit.eolonly",
        #"%s -cp \"%s/*\" -mx5g edu.stanford.nlp.sentiment.SentimentPipeline -stdin",
        java.path, stanford.tagger
    )

    results <- system(cmd, input = text.var, intern = TRUE, ignore.stderr = TRUE)

    as.numeric(.mgsub(c(".*Very negative", ".*Negative", ".*Neutral",
        ".*Positive", ".*Very positive"), seq(-1, 1, by = 0.5),
        results, fixed = FALSE))
}


