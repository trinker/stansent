#' Wrappper to Standford's coreNLP Sentiment Tagger
#'
#' Tag sentiment as most negative (-1) to most positive (+1).  A
#' reimplementation of Matthew Jocker's Stanford coreNLP wrapper in \pkg{syuzhet}.
#'
#' @param text.var The text variable.
#' @param stanford.tagger path to the Stanford tagger.
#' @references \url{http://www.matthewjockers.net/2015/03/04/some-thoughts-on-annies-thoughts-about-syuzhet}
#' @keywords sentiment
#' @export
#' @examples
#' \dontrun{
#' if (!require("pacman")) install.packages("pacman")
#' pacman::p_load_gh("trinker/qdap", "trinker/sentimentr")
#' pacman::p_load(syuzhet)
#'
#' text_vector <- unlist(presidential_debates_2012[1:100, "dialogue"])
#' sents <- get_sentences_nlp(text_vector)
#' senti <- sentiment_stanford(sents)
#'
#'
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
#' sents <- sentimentr::get_sentences(text_vector)
#'
#' senti <- lapply(sents[[1]], sentiment_stanford)
#'
#' syuzhet <- setNames(as.data.frame(lapply(c("bing", "afinn", "nrc"),
#'     function(x) get_sentiment(sents[[1]], method=x))), c("bing", "afinn", "nrc"))
#'
#' width <- options()$width
#' options(width=1000)
#'
#' left_just(data.frame(
#'     stanford = unlist(senti),
#'     sentimentr = round(sentiment(sents, question.weight = 0)[["sentiment"]], 2),
#'     syuzhet,
#'     sentences = unlist(sents),
#'     stringsAsFactors = FALSE
#' ), "sentences")
#'
#' options(width=width)
#' }
sentiment_stanford <- function(text.var,
    stanford.tagger = file.path(strsplit(getwd(), "(/|\\\\)+")[[1]][1], "stanford-corenlp-full-2015-04-20")){

    if (!file.exists(stanford.tagger)) stop("%s does not seem to be valid", stanford.tagger)

    message("\nAnalyzing text for sentiment...\n");flush.console()


    WD <- getwd()
    on.exit(setwd(WD))
    setwd(stanford.tagger)

    cmd <- paste('java -cp "*" -mx5g edu.stanford.nlp.sentiment.SentimentPipeline -stdin', sep="")
    results <- system(cmd, input = text.var, intern = TRUE, ignore.stderr = TRUE)

    setwd(WD)

    as.numeric(.mgsub(
        c(".*Very negative", ".*Negative", ".*Neutral", ".*Positive", ".*Very positive"),
        seq(-1, 1, by = .5),
        results, fixed = FALSE
    ))
}




