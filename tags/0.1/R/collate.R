#' @include roxygen.R
#' @include string.R
#' @include functional.R
#' @include roclet.R
#' @include description.R
#' @include parse.R
roxygen()

#' Collate value parser
#' @name include
#' @seealso make.collate.roclet
register.preref.parsers(parse.value,
                        'include')

#' Make collate roclet which parses the given files; topologically
#' sorting \code{@@include}s, and either merging the \code{Collate:}
#' directive with a pre-existing \file{DESCRIPTION} or writing to
#' standard out.
#'
#' Each \code{@@include} tag should specify the filename of one intrapackage
#' dependency; multiple \code{@@include} tags may be given.
#'
#' Contains the member function \code{parse} which parses an arbitrary number
#' of files, and \code{parse.dir} which recursively parses a directory tree.
#'
#' @param merge.file \file{DESCRIPTION} file with which to merge directive;
#' or \code{NULL} for none
#' @param target.file whither to \code{cat} directive (whether merged or
#' not); blank line is standard out
#' @param verbose whether to describe what we're doing with the
#' target.file
#' @return Rd roclet
#' @seealso \code{\link{make.roclet}}
#' @examples
#' #' `example-a.R', `example-b.R' and `example-c.R' reside
#' #' in the `example' directory, with dependencies
#' #' a -> {b, c}. This is `example-a.R'.
#' #' @@include example-b.R
#' #' @@include example-c.R
#' roxygen()
#'
#' roclet <- make.collate.roclet()
#' \dontrun{roclet$parse.dir('example')}
#' @export
make.collate.roclet <- function(merge.file=NULL,
                                target.file='',
                                verbose=TRUE) {
  vertices <- NULL

  make.vertex <- function(file) {
    vertex <- new.env(parent=emptyenv())
    vertex$file <- trim(file)
    vertex$discovered <- FALSE
    vertex$ancestors <- NULL
    vertex
  }

  maybe.append.vertex <- function(file)
    if (is.null(vertices[[file]]))
      assign.parent('vertices',
                    append(vertices,
                           as.list(structure(c(make.vertex(file)),
                                             names=file))),
                    environment())

  member <- function(ancestor, ancestors) {
    for (vertex in ancestors)
      if (identical(ancestor, vertex))
        TRUE
    FALSE
  }

  maybe.append.ancestor <- function(predecessor, ancestor)
    if (!member(ancestor, predecessor$ancestors))
      predecessor$ancestors <-
        append(ancestor, predecessor$ancestors)

  current.predecessor <- NULL

  parse.include <- function(key, file) {
    file <- trim(file)
    maybe.append.vertex(file)
    ancestor <- vertices[[file]]
    maybe.append.ancestor(current.predecessor,
                          ancestor)
  }
  
  pre.parse <- function(partitum) {
    file <- partitum$srcref$filename
    maybe.append.vertex(file)
    vertex <- vertices[[file]]
    assign.parent('current.predecessor',
                  vertex,
                  environment())
  }

  topological.sort <- function(vertices) {
    sorted <- NULL
    visit <- function(predecessor) {
      predecessor$discovered <- TRUE
      for (ancestor in predecessor$ancestors)
        if (!ancestor$discovered)
          visit(ancestor)
      assign.parent('sorted',
                    append(sorted, predecessor),
                    environment())
    }
    for (vertex in vertices)
      if (!vertex$discovered)
        visit(vertex)
  }

  COLLATE.FIELD <- 'Collate:'

  merge <- function(files) {
    if (verbose && !is.null.string(target.file))
      cat(sprintf('Merging collate directive with %s to %s',
                  merge.file,
                  target.file), '\n')
    pre.parse <- function(parsed.fields) unlink(target.file)
    post.parse <- function(parsed.fields)
      cat.description('Collate', files, file=target.file)
    parse.default <- Curry(cat.description, file=target.file)
    parser <- make.description.parser(parse.default,
                                      pre.parse=pre.parse,
                                      post.parse=post.parse)
    parser$register.parser('Collate', noop.description)
    ## Force parse.description.file to be evaluated before
    ## parser$parser (applicative order).
    parsed.file <- parse.description.file(merge.file)
    parser$parse(parsed.file)
  }

  post.files <- function() {
    files <- do.call(paste, Map(function(vertex)
                                sprintf("'%s'", vertex$file),
                                topological.sort(vertices)))
    if (!is.null(cwd))
      setwd(cwd)
    assign.parent('cwd', NULL, environment())
    if (!is.null(merge.file))
      merge(files)
    else
      cat.description('Collate', files, file=target.file)
  }

  roclet <- make.roclet(parse.include,
                        pre.parse=pre.parse,
                        post.files=post.files)

  roclet$register.default.parser('include')

  cwd <- NULL

  roclet$parse.dir <- function(dir) {
    assign.parent('cwd', getwd(), environment())
    setwd(dir)
    do.call(roclet$parse,
            as.list(list.files('.',
                               recursive=TRUE,
                               full.names=FALSE)))
  }

  roclet
}
