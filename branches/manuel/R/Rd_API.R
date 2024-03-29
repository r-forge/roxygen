

### Composed Rd tag elements (mainly for S4 purpose):
### TODO: rewrite using code, emph, etc. tags and overload +
### to compose tags.

slotTag <- function(name, description=NULL, type=NULL, default=NULL) {
  return(itemTag(sprintf('\\code{%s}:',
                         name),
                 sprintf('(\\code{\\link{%s}}) %s',
                         trim(type),
                         trim(description))))
}

slotsTag <- function(..., x=list(...)) {
  return(sectionTag('Slots', list(describeTag(x))))
}

prototypeTag <- function(name, value, inherit) {
  return(itemTag(sprintf(ifelse(inherit,
                                '\\emph{\\code{%s}} =',
                                '\\code{%s} ='),
                         name),
                 sprintf('%s',
                         trim(value))))
}

prototypesTag <- function(..., x=list(...)) {
  return(sectionTag('Prototype', list(describeTag(x))))
}

containsTag <- function(..., x=list(...)) {
  return(sectionTag('Extends',
                    list(textTag(paste('\\code{\\linkS4class{', x, '}}',
                                       collapse=', ', sep='')))))
}

classmethodSignature <- function(signature)
  sprintf('signature(%s)',
          paste(names(signature), dQuote(signature),
                sep=' = ', collapse=', '))  

classmethodTag <- function(generic, name, signature, description) {
  return(itemTag(sprintf('\\code{\\link[=%s]{%s}}',
                         name,
                         generic),
                 sprintf('\\code{%s}: %s',
                         classmethodSignature(signature),
                         trim(description))))
}

classmethodsTag <- function(..., x=list(...)) {
  return(sectionTag('Methods', list(describeTag(x))))
}


### Rd tag elements:

nameTag <- function(x) {
  return(Rd_tag(verbTag(x), '\\name'))
}

aliasTag <- function(x) {
  return(Rd_tag(verbTag(x), '\\alias'))
}

keywordTag <- function(x) {
  return(Rd_tag(textTag(x), '\\keyword'))
}

detailsTag <- function(..., x=list(...)) {
  .totext <- function(t) {
    if ( is(t, 'Rd_tag') ) t else textTag(t)
  }

  return(Rd_tag(lapply(x, .totext), '\\details'))
}

itemTag <- function(x, y=NULL) {
  if ( is.list(x) )
    y <- x[[2]]; x <- x[[1]]
  
  return(Rd_tag(list(list(textTag(trim(x))),
                     list(textTag(trim(y)))), '\\item'))
}

argumentsTag <- function(..., x=list(...), newline=TRUE) {
  if ( newline )
    x <- newlineSeperators(x)
    
  return(Rd_tag(x, '\\arguments'))
}

methodTag <- function(x, y) {
  return(Rd_tag(list(list(textTag(x)),
                     list(textTag(y))), '\\method'))
}

S4methodTag <- function(x, y) {
  return(Rd_tag(list(list(textTag(x)),
                     list(textTag(y))), '\\S4method'))
}

usageTag <- function(x, y) {
  y <- sprintf('(%s)', paste(strwrap(y, exdent=4), collapse="\n"))
  tag <- Rd_tag(list(x, rcodeTag(y)), '\\usage')
  tag <- Rd_tag_append_tag(tag, newlineTag(), newline=FALSE)

  return(tag)
}

sectionTag <- function(x, y) {
  return(Rd_tag(list(list(textTag(x)), y), '\\section'))
}

describeTag <- function(x) {
  return(Rd_tag(x, '\\describe'))
}

newlineTag <- function() {
  return(textTag('\n'))
}

newlineSeperators <- function(x) {
  l <- 2 * length(x)
  
  t <- vector('list', length=l)
  t[seq(1, l, by=2)] <- x
  t[seq(2, l, by=2)] <- newlineTag()
  
  return(t)
}


### Basic tag elements:

Rd_tag <- function(x, tag) {
  UseMethod('Rd_tag')
}
  
Rd_tag.default <- function(x, tag) {
  return(structure(as.character(x), Rd_tag=tag, class='Rd_tag'))
}

Rd_tag.Rd_tag <- function(x, tag) {
  return(structure(list(x), Rd_tag=tag, class='Rd_tag'))
}

Rd_tag.list <- function(x, tag) {
  return(structure(x, Rd_tag=tag, class='Rd_tag'))
}
 
verbTag <- function(x) {
  return(Rd_tag(x, 'VERB'))
}

textTag <- function(x) {
  return(Rd_tag(x, 'TEXT'))
}

rcodeTag <- function(x) {
  return(Rd_tag(x, 'RCODE'))
}

Rd_tag_append_tag <- function(tag1, tag2, newline=TRUE) {

  attr <- attributes(tag1)
  tag1 <- c(tag1, tag2)
  attributes(tag1) <- attr

  if ( newline )
    tag1 <- Rd_tag_append_tag(tag1, newlineTag(), newline=FALSE)
 
  return(tag1)
}



### Rd functions:

Rd_append_tag <- function(rd, tag, at=NULL, newline=TRUE) {
  if ( is.null(at) )
    at <- length(rd) + 1
  
  rd[[at]] <- tag

  if ( newline ) 
    rd[[at+1]] <- newlineTag()
  
  return(rd)
}



### Rd element:

Rd <- function() {
  return(structure(list(), class='Rd'))
}
