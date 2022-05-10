#' Take local code and upload to a named gist
#'
#' @param content the code, either the currently highlighted file or manually indicated code
#' @param gist_name a valid filename ie my-code.R
#' @import gistr gistfo
#' @return gist id and the gist URL to clipboard
#' @export

gist_upload <- function(content = NULL, gist_name = NULL, ...) {
  # code largely adapted from: https://github.com/MilesMcBain/gistfo

  stopifnot("Please give a filename with a valid file extension, like 'code.R'" = !is.null(gist_name))

  if (is.null(content)) {
    message("Using current file")

    source_context <- rstudioapi::getSourceEditorContext()

    gist_content <- source_context$selection[[1]]$text
    if (gist_content == "") {
      gist_content <- paste0(source_context$contents, collapse = "\n")
    }
  } else {
    gist_content <- paste0(content, collapse = "\n")
  }

  gist_file <- file.path(tempdir(), gist_name)

  cat(gist_content, file = gist_file)

  the_gist <- gistr::gist_create(
    files = gist_file,
    public = TRUE,
    browse = FALSE,
    filename = gist_name,
    ...
  )

  # Add URL to gist as comment at bottom of gist
  if (gistfo:::is_file_ext(gist_name, "r", "html", "r?md", "md", "q?md", "js", "cpp", "py")) {
    gist_url <- the_gist$html_url
    comment <- gistfo:::comment_single_line(gist_name, gist_url)
    cat(comment, file = gist_file, append = TRUE)
    the_gist <- gistr::update_files(the_gist, gist_file)
    gistr::update(the_gist)
  }

  utils::browseURL(the_gist$html_url)

  gistfo:::maybe_clip(gist_url)
  return(the_gist$id)
}
