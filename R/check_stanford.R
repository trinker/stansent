#' Check if Stanford coreNLP is Installed and In Root
#'
#' Checks that Stanford coreNLP is installed and in root.
#'
#' @param stanford The version of Stanford's coreNLP.
#' @param download The download url for Stanford's coreNLP.
#' @keywords stanford
#' @references http://nlp.stanford.edu/software/corenlp.shtml
#' @export
#' @examples
#' \dontrun{
#' check_stanford_installed()
#' }
check_stanford_installed <- function(stanford = "stanford-corenlp-full-2015-12-09",
    download = "http://nlp.stanford.edu/software/stanford-corenlp-full-2015-12-09.zip"){
    message("\nchecking if Java is installed...\n")
    root <- strsplit(getwd(), "(/|\\\\)+")[[1]][1]
    out <- stanford %in% dir(file.path(root, ""))
    mess <- ifelse(out, paste0("Stanford coreNLP appears to be installed.\n\n",
        "...Let the NLP tagging begin!\n\n"),
        "Stanford coreNLP does not appear to be installed in root.\nWould you like me to try to install it there?")
    message(mess)
    if (out) return(invisible(NULL))
    ans <- utils::menu(c("Yes", "No"))
    if (ans == "2") {
        stop("Please consider installing yourself...\n\nhttp://nlp.stanford.edu/software/corenlp.shtml")
    } else {
        message("Let me try...\nHold on.  It's large and may take some time...\n")
    }

    temp <- tempdir()
    dest <- file.path(temp, basename(download))
    download.file(download, dest)
    utils::unzip(dest, exdir = temp)
    stan <- gsub("\\.zip$", "", dest)
    if (!file.exists(stan)) stop(
        "I let you down :-/\nIt appears the file was not downloaded.\n",
        "Consider installing yourself via:\n\n",
        "http://nlp.stanford.edu/software/corenlp.shtml\n\n"
    )
    file.copy(stan, file.path(root, "/"), , TRUE)
    if (file.exists(file.path(root, basename(stan)))) message(
        "I have done it...\nStanford's coreNLP appears to be installed.\n\n",
        "...Let the NLP tagging begin!\n\n"
    )
}

