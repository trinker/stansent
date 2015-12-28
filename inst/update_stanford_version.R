update_stanford_version <- function(){
    pacman::p_load(rvest, xml2)

    verout <- c("#' Stanford coreNLP Version", "#'", "#' A constant stating the version of coreNLP used as the package default.",
        "#'", "#' @export", "#' @references \\url{http://stanfordnlp.github.io/CoreNLP/index.html#download}",
        "#' @examples", "#' version", "coreNLP_version <- \"%s\"\n")
    verout <- paste(verout, collapse="\n")

    "http://stanfordnlp.github.io/CoreNLP/index.html#download" %>%
      xml2::read_html() %>%
      rvest::html_nodes(".downloadbutton") %>%
      rvest::html_attr("href") %>%
      basename() %>%
      gsub("\\.zip$", "", .) %>%
      sprintf(verout, .) %>%
      cat(., file = "R/version.R")

    message("Version updated")
}
