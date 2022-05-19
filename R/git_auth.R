#' Authorize with GitHub.
#'
#' This function is run automatically to allow gistillery to access your GitHub
#' account. It is adapted from gistr::gist_auth
#'
#' There are two ways to authorise gistillery to work with your GitHub account:
#'
#' - Generate a personal access token with the gist scope selected, and set it
#' as the `GITHUB_PAT` environment variable per session using `Sys.setenv`
#' or across sessions by adding it to your `.Renviron` file or similar.
#' See
#' https://help.github.com/articles/creating-an-access-token-for-command-line-use
#' for help
#' - Interactively login into your GitHub account and authorise with OAuth.
#'
#' Using `GITHUB_PAT` is recommended.
#'
#' @export
#' @param app An [httr::oauth_app()] for GitHub. The default uses an
#' application `gistr_oauth` created by Scott Chamberlain.
#' @param reauth (logical) Force re-authorization?
#' @importFrom gitcreds gitcreds_get
#' @import httr
#' @return a character string - used downstream for auth in various functions

git_auth <- function(app = gistr_app, reauth = FALSE) {

  # code adapted from gistr
  # https://github.com/ropensci/gistr/blob/master/R/gist_auth.R
  if (exists("auth_config", envir = cache) && !reauth) {
    return(auth_header(cache$auth_config$auth_token$credentials$access_token))
  }

  pat <- Sys.getenv("GITHUB_PAT", "")

  if (!identical(pat, "")) {
    auth_config <- list(auth_token = list(credentials = list(access_token = pat)))
  } else if (!interactive()) {
    stop("In non-interactive environments, please set GITHUB_PAT env to a GitHub",
      " access token (https://help.github.com/articles/creating-an-access-token-for-command-line-use)",
      call. = FALSE
    )
  } else {
    endpt <- httr::oauth_endpoints("github")

    # try gitcreds
    token <- gitcreds::gitcreds_get()
    if (nzchar(token$password)) {
      token <- paste0("token ", token$password)
      return(token)
      auth_config <- httr::config(token = token)
    } else {
      # try oauth direct
      token <- httr::oauth2.0_token(endpt, app, scope = "gist", cache = !reauth)
      auth_config <- httr::config(token = token)
    }

  }

  cache$auth_config <- auth_config

  if(grepl("token", token, ignore.case = TRUE)) {
    return(token)
  } else {
    auth_header(auth_config$auth_token$credentials$access_token)
  }

  if(nchar(token) <= 7) {
      cli::cli_alert_danger("Github Auth Token appears to be missing.")
      cli::cli_alert_warning("Please set {.field GITHUB_PAT} in your {.file .Renviron} or use the {.pkg gitcreds} package.")
  }

}

auth_header <- function(x) paste0("token ", x)

cache <- new.env(parent = emptyenv())

gistr_app <- httr::oauth_app(
  "gistr_oauth",
  "89ecf04527f70e0f9730",
  "77b5970cdeda925513b2cdec40c309ea384b74b7"
)

msg <- function(wh) {
  msgs <- c(
    no_git = paste0(
      "No git installation found. You need to install git and set up ",
      "your GitHub Personal Access token using `gitcreds::gitcreds_set()`."
    ),
    no_creds = paste0(
      "No git credentials found. Please set up your GitHub Personal Access ",
      "token using `gitcreds::gitcreds_set()`."
    )
  )
  msgs[wh]
}
