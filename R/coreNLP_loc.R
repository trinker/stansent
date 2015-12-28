#' Make User Specific Path/URL to coreNLP
#'
#' Make a user specific path/URL to coreNLP.
#'
#' @param version The verson of coreNLP.
#' @return returns a path as a string.
#' @rdname coreNLP_loc
#' @export
#' @examples
#' coreNLP_loc()
coreNLP_loc <- function(version = stansent::coreNLP_version){
    file.path(strsplit(getwd(), "(/|\\\\)+")[[1]][1], version)
}

#' @rdname coreNLP_loc
#' @export
coreNLP_url <- function(version = stansent::coreNLP_version){
    sprintf("http://nlp.stanford.edu/software/%s.zip", version)
}


