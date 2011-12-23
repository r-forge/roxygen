
.onAttach <- function(libname, pkgname) {
  packageStartupMessage(paste("This is roxygen 0.3-2:\n",
                              " Please note that roxygen is no longer being\n",
                              " actively developed. Please see its successor\n",
                              " roxygen2 on CRAN!\n"))
  return(TRUE)
}
