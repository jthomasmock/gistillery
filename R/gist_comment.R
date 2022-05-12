#' Add a comment to an existing gist
#'
#' @param gist_id Character string indicating the gist ID
#' @param comment The comment text
#'
#' @return A string of the comment text
#' @export
#' @import httr2
#' @importFrom gistr gist_auth
#' @importFrom httr2 %>%
#' @importFrom jsonlite toJSON
#'
gist_comment <- function(gist_id, comment){

  gist_error_body <- function(resp) {
    body <- httr2::resp_body_json(resp)

    message <- body$message
    if (!is.null(body$documentation_url)) {
      message <- c(message, paste0("See docs at <", body$documentation_url, ">"))
    }
    message
  }

  token <- ifelse(!is.null(token), token, Sys.getenv("GITHUB_PAT"))

  req_built <- "https://api.github.com" |>
    request() |>
    req_url_path_append("gists") |>
    req_url_path_append(gist_id) |>
    req_url_path_append("comments") |>
    req_headers(
      gistr::gist_auth(),
      "User-Agent" = "gistr",
      Accept = "application/vnd.github.v3+json"
    ) |>
    httr2::req_body_json(
      list(body = comment)
    ) |>
    req_error(body = gist_error_body)

  httr2::req_perform(req_built)

}

