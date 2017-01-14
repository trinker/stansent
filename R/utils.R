abbr_rep <- lapply(list(
  Titles   = c('jr', 'mr', 'mrs', 'ms', 'dr', 'prof', 'sr', 'sen', 'rep',
         'rev', 'gov', 'atty', 'supt', 'det', 'rev', 'col','gen', 'lt',
         'cmdr', 'adm', 'capt', 'sgt', 'cpl', 'maj'),

  Entities = c('dept', 'univ', 'uni', 'assn', 'bros', 'inc', 'ltd', 'co',
         'corp', 'plc'),

  Months   = c('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul',
         'aug', 'sep', 'oct', 'nov', 'dec', 'sept'),

  Days     = c('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'),

  Misc     = c('vs', 'etc', 'no', 'esp', 'cf', 'al', 'mt'),

  Streets  = c('ave', 'bld', 'blvd', 'cl', 'ct', 'cres', 'dr', 'rd', 'st')
), function(x){
    fl <- sub("(^[a-z])(.+)", "\\1", x)
    sprintf("[%s%s]%s", fl, toupper(fl), sub("(^[a-z])(.+)", "\\2", x))
})

period_reg <- paste0(
    "(?:(?<=[a-z])\\.\\s(?=[a-z]\\.))",
        "|",
    "(?:(?<=([ .][a-z]))\\.)(?!(?:\\s[A-Z]|$)|(?:\\s\\s))",
        "|",
    "(?:(?<=[A-Z])\\.(?=\\s??[A-Z]\\.))",
        "|",
    "(?:(?<=[A-Z])\\.(?!\\s+[A-Z][A-Za-z]))"  #added \\s to \\s+ to handle 'I went to AU.  Awesome school.'
)




sent_regex <- sprintf("((?<=\\b(%s))\\.)|%s|(%s)",
    paste(unlist(abbr_rep), collapse = "|"),
    period_reg,
	'\\.(?=\\d+)'
)

sent_regex2 <- sprintf("((?<=\\b(%s))\\.)|%s|(%s)",
    paste(unlist(abbr_rep), collapse = "|"),
    period_reg,
	'\\.(?=\\d+)'
)

get_sents <- function(x) {
    if (methods::is(x, "get_sentences")) return(x)
    y <- stringi::stri_replace_all_regex(trimws(x), sent_regex, "<<<TEMP>>>")
    z <- stringi::stri_split_regex(y, "(?<!\\w\\.\\w.)(?<![A-Z][a-z]\\.)(?<=\\.|\\?|\\!)(\\s|(?=[a-zA-Z][a-zA-Z]*\\s))")
    lapply(z, function(x) gsub("<<<temp>>>", "", stringi::stri_trans_tolower(x)))
}

# get_sents <- function(x) {
#     if (methods::is(x, "get_sentences")) return(x)
#     y <- stringi::stri_replace_all_regex(trimws(x), sent_regex, "")
#     z <- stringi::stri_split_regex(y, "(?<!\\w\\.\\w.)(?<![A-Z][a-z]\\.)(?<=\\.|\\?|\\!)(\\s|(?=[a-zA-Z][a-zA-Z]*\\s))")
#     lapply(z, stringi::stri_trans_tolower)
# }

# get_sents <- function(x) {
# 	if (methods::is(x, "get_sentences")) return(x)
#     y <- stringi::stri_trans_tolower(stringi::stri_replace_all_regex(trimws(x), sent_regex, ""))
#     stringi::stri_split_regex(y, "(?<!\\w\\.\\w.)(?<![A-Z][a-z]\\.)(?<=\\.|\\?|\\!)(\\s|(?=[a-zA-Z][a-zA-Z]*\\s))")
# }


#get_sents <- function(x) {
#	if (is(x, "get_sentences")) return(x)
#    x <- stringi::stri_trans_tolower(stringi::stri_replace_all_regex(x, sent_regex, ""))
#    stringi::stri_split_regex(x, "(?<!\\w\\.\\w.)(?<![A-Z][a-z]\\.)(?<=\\.|\\?|\\!)(\\s|(?=[a-zA-Z][a-zA-Z]*\\s))")
#}

get_sents2 <- function(x) {
    y <- stringi::stri_replace_all_regex(trimws(x), sent_regex, "<<<TEMP>>>")
    stringi::stri_split_regex(y, "(?<!\\w\\.\\w.)(?<![A-Z][a-z]\\.)(?<=\\.|\\?|\\!)(\\s|(?=[a-zA-Z][a-zA-Z]*\\s))")
}

add_row_id <- function(x){
    lens <- lapply(x, length)
    rep(seq_along(lens), unlist(lens))
}

count_words <- function(x){
    stringi::stri_count_words(x)
}

make_words <- function(x, hyphen = ""){
	  if (hyphen != "") x <- gsub("-", hyphen, x)
    lapply(stringi::stri_split_regex(gsub("^\\s+|\\s+$", "", x), "[[:space:]]|(?=[,;:])"), function(y) gsub('~{2,}', ' ', y))
}

#' @importFrom data.table :=
make_sentence_df2 <- function(sents){

    indx <- wc <- NULL

    ids <- add_row_id(sents)
    text.var <- gsub("[^a-z',;: ]|\\d:\\d|\\d ", "", unlist(sents))
    dat <- data.frame(
        id = ids,
        sentences = text.var,
    	  wc = count_words(text.var),
        stringsAsFactors = FALSE
    )
    data.table::setDT(dat)
    dat[, indx:= wc < 1, by=c('id', 'sentences', 'wc')][(indx), c('sentences', 'wc'):=NA][, indx:=NULL]
}


.mgsub <- function (pattern, replacement, text.var, fixed = TRUE,
	order.pattern = fixed, ...) {

    if (fixed && order.pattern) {
        ord <- rev(order(nchar(pattern)))
        pattern <- pattern[ord]
        if (length(replacement) != 1) replacement <- replacement[ord]
    }
    if (length(replacement) == 1) replacement <- rep(replacement, length(pattern))

    for (i in seq_along(pattern)){
        text.var <- gsub(pattern[i], replacement[i], text.var, fixed = fixed, ...)
    }

    text.var
}


rm_na <- function(x) {
	log2NA(x[!is.na(x)])
}

log2NA <- function(x) {
	x[identical(logical(0), x)] <- NA
	x
}

sum2 <- function(x) sum(x, na.rm = TRUE)


paste2 <- function (multi.columns, sep = ".", handle.na = TRUE, trim = TRUE) {
    if (is.matrix(multi.columns)) {
        multi.columns <- data.frame(multi.columns, stringsAsFactors = FALSE)
    }
    if (trim)
        multi.columns <- lapply(multi.columns, function(x) {
            gsub("^\\s+|\\s+$", "", x)
        })
    if (!is.data.frame(multi.columns) & is.list(multi.columns)) {
        multi.columns <- do.call("cbind", multi.columns)
    }
    if (handle.na) {
        m <- apply(multi.columns, 1, function(x) {
            if (any(is.na(x))) {
                NA
            } else {
                paste(x, collapse = sep)
            }
        })
    } else {
        m <- apply(multi.columns, 1, paste, collapse = sep)
    }
    names(m) <- NULL
    return(m)
}

