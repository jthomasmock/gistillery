#' Add a comment to an existing gist
#'
#' @param gist_id Character string indicating the gist ID
#' @param body The comment text
#' @param ... Additional arguments passed to `gistr:::gist_post()`
#'
#' @return A string of the comment text
#' @export
#' @import gistr
#' @importFrom jsonlite toJSON
#'
gist_comment <- function(
    gist_id,
    body = "![](pbs.twimg.com/media/FBGfjADUYAUxiPz?format=png)", ...) {
  if (is.null(gist_id)) stop("Please provide a gist_id", call. = FALSE)
  body <- jsonlite::toJSON(list(body = body), auto_unbox = TRUE)
  res <- gistr:::gist_POST(paste0(gistr:::ghbase(), "/gists/", gist_id, "/comments"), gistr::gist_auth(), gistr:::ghead(), body, ...)
  res$body
}
