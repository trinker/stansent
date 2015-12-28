#' Check if Java is Installed and Correct Version
#'
#' Checks that Java is installed and of the correct version.
#'
#' @param verbose If \code{TRUE} messages are printed even when everything is
#' installed.
#' @keywords java
#' @export
#' @examples
#' \dontrun{
#' check_java()
#' }
check_java <- function(verbose = TRUE){
    java_is_installed <- check_java_installed(verbose = verbose)
    if (!java_is_installed) stop(
        "Java doesn't appear to be installed.\n",
        "Check to see if it is installed and on your path.\n\n",
        "https://www.java.com/en/download\n\n"
    )
    java_is_correct_version <- check_java_version(verbose = verbose)
    if (!java_is_correct_version) stop(
        "Minimal version of Java not installed.  Download:\n\n",
        "https://www.java.com/en/download\n\n"
    )
    if (isTRUE(verbose)) message("Java appears to be installed and at least of the minimal version.")
}

check_java_version <- function(min.ver = stansent::java_version, verbose = TRUE){
    if (isTRUE(verbose)) message("\nchecking minimal Java version...\n")
    java <- try(system("java -version", intern = TRUE))
    ver <- qdapRegex::rm_between(java, '"', '"', extract=TRUE)[[1]]
    numeric_version(gsub("_", "-", ver)) > min.ver
}

check_java_installed <- function(verbose = TRUE) {
    if (isTRUE(verbose)) message("\nchecking if Java is installed...\n")
    out <- try(system('java -version', show.output.on.console = verbose) == 0)
    if (inherits(out, "try-error")) out <- FALSE
    out
}
