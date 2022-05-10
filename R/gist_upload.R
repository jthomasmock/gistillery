#' Take local code and upload to a named gist
#'
#' @param content the code, either the currently highlighted file or manually indicated code
#' @param gist_name a valid filename ie my-code.R
#' @import gistr gistfo
#' @inherit gistr::gist_create
#' @return gist id and the gist URL to clipboard, can be piped directly into gist_to_carbon
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

  gist_url <- the_gist$html_url

  # Add URL to gist as comment at bottom of gist
  if (is_file_ext(gist_name, "r", "html", "r?md", "md", "q?md", "js", "cpp", "py")) {

    comment <-  glue::glue("\n\n# {gist_url}\n", .trim = FALSE)
    cat(comment, file = gist_file, append = TRUE)
    the_gist <- gistr::update_files(the_gist, gist_file)
    gistr::update(the_gist)
  }

  utils::browseURL(gist_url)

  # try to put it out to clipboard
  maybe_clip(gist_url)
  # return id for piping to gist_to_carbon
  return(the_gist$id)

  # print the URL as well
  print(gist_url)
}

# vendored from: https://github.com/MilesMcBain/gistfo/blob/master/R/gistfo.R#L155-L159
maybe_clip <- function(text) {
  has_clipr <- requireNamespace("clipr", quietly = TRUE)
  if (has_clipr && clipr::clipr_available()) {
    clipr::write_clip(text)
  }
  text
}

# vendored from: https://github.com/MilesMcBain/gistfo/blob/master/R/gistfo.R#L104-L107
is_file_ext <- function(path, ...) {
  exts <- paste(tolower(c(...)), collapse = "|")
  grepl(glue::glue("[.]({exts})$"), tolower(path))
}
