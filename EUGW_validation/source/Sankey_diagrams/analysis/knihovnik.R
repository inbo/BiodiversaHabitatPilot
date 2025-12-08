# knihovnik
# this function checks, whether there are all packages downloaded (if not, asks user, if installation is wanted and do so). at the end, attach all input packages with library() function

knihovnik <- function(...) {
  # take input as a string, drop "list"
  kniha <- as.character(substitute(list(...)))[-1L]
  
  # check if those exists !! this only searches for packages on CRAN !!
  available <- rownames(available.packages())
  nonexist <- kniha[!(kniha %in% available)]
  
  # return warning for nonexisting packages
  if (length(nonexist) > 0) {
    warning("Those packages likely dont exist, they will be skiped: ",
            paste(nonexist, collapse = ", "),
            call. = FALSE)
    kniha <- setdiff(kniha, nonexist)
  }
  
  # noninstalled packages
  not_installed <- kniha[!(kniha %in% installed.packages()[, "Package"])]
  
  if (length(not_installed) > 0) {
    cat("Not installed packages:\n")
    cat(paste("-", not_installed), sep = "\n")
    cat("Install them now?? [y/n]: ")
    response <- tolower(readline())
    
    if (!response %in% c("y", "yes")) {
      return(cat("Cancelled.\n"))
    }
    
    install.packages(not_installed, dependencies = TRUE)
  }
  
  # load packages
  for (kapitola in kniha) {
    suppressPackageStartupMessages(library(kapitola, character.only = TRUE))
    cat("DONE", kapitola, "\n")
  }
}
