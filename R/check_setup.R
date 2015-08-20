#' Check the Java/Stanford coreNLP Setup
#'
#' Check to make sure that Java is installed and of correct version and that
#' Stanford's coreNLP is installed and in root.
#'
#' @keywords setup
#' @export
#' @examples
#' \dontrun{
#' check_setup()
#' }
check_setup <- function(){
    check_java()
    check_stanford_installed()
}

