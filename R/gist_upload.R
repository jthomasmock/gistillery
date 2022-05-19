#' Take local code and upload to a named gist
#'
#' @param content the code, either the currently highlighted file or manually indicated code
#' @param gist_name a valid filename ie my-code.R
#' @param description a brief description of the gist or it's purpose
#' @param public a logical, defaults to TRUE, indicates whether to make gist public or not
#' @param browse a logical, defaults to TRUE, indicates whether to open the new gist in browser or not
#' @import httr2
#' @importFrom glue glue
#' @importFrom httr2 %>%
#' @return gist id and the gist URL to clipboard, can be piped directly into gist_to_carbon
#' @export

gist_upload <- function(content = NULL, gist_name = NULL, description = "",
  public = TRUE, browse = TRUE) {

  # Some code adapted from: https://github.com/MilesMcBain/gistfo
  stopifnot("Please give a filename with a valid file extension, like 'code.R' or `slither.py`" = !is.null(gist_name))
  stopifnot("Please give a filename with a valid file extension, like 'code.R' or `slither.py`" = nzchar(tools::file_ext(gist_name)))

  if (is.null(content)) {
    message("Using currently opened file")

    source_context <- rstudioapi::getSourceEditorContext()

    gist_content <- source_context$selection[[1]]$text

    if (gist_content == "") {
      gist_content <- paste0(source_context$contents, collapse = "\n")
    }
  } else {
    gist_content <- paste0(content, collapse = "\n")
  }

  # core request
  req_gist <- "https://api.github.com" %>%
    httr2::request() %>%
    httr2::req_url_path_append("gists") %>%
    httr2::req_headers(
      Authorization = git_auth(),
      "User-Agent" = "gistr",
      Accept = "application/vnd.github.v3+json"
    )

  # build the file for upload
  built_body <- list(
    description = description,
    files = list(gist_name = list(content = gist_content)),
    public = public
  )

  # fill with gist_name
  names(built_body$files) <- gist_name

  req_add_body <- req_gist %>%
    httr2::req_body_json(built_body) %>%
    httr2::req_error(body = gist_error_body)

  req_out <- httr2::req_perform(req_add_body)

  # return id and URL for returning/other use
  id <- httr2::resp_body_json(req_out)$id
  gist_url <- httr2::resp_body_json(req_out)$html_url

  # Add URL to gist as comment at bottom of gist
  url_comment <- glue::glue("\n\n# Gist URL {gist_url}\n", .trim = FALSE)
  add_url_content <- paste0(gist_content, url_comment, collapse = "")

  # rename the element with gist_name

  comment_body <- list(
    files = list(gist_name = list(content = add_url_content))
    )
  names(comment_body$files) <- gist_name

  # build the request
  req_update <- req_gist %>%
    httr2::req_url_path_append(id) %>%
    httr2::req_body_json(comment_body) %>%
    httr2::req_method("PATCH")

  # send the add url request
  gist_with_url <- httr2::req_perform(req_update)

  # open file in browser
  if(browse) utils::browseURL(gist_url)

  # try to put it out to clipboard
  maybe_clip(gist_url)
  # return id for piping to gist_to_carbon
  return(id)

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

gist_error_body <- function(resp) {
  body <- httr2::resp_body_json(resp)

  message <- body$message
  if (!is.null(body$documentation_url)) {
    message <- c(message, paste0("See docs at <", body$documentation_url, ">"))
  }
  message
}
