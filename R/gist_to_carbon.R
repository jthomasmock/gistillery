#' Take an existing gist, send to carbon, and save the image locally
#'
#' @param gist_id the unique id for your existing gist, can be piped from gist_upload() or passed manually.
#' @param file the name of the file for printing, eg code.png
#' @param bg A valid hex code for color, ie #D3D3D3
#' @param theme A valid theme, such as "cobalt", "nord", "night-owl", "monokai" - for all available themes, see `carbon_themes`
#' @param font A valid font ID such as "IBM+Plex+Mono", "Hack", "Fira+Code" - for all available fonts, see `carbon_fonts`
#' @param lang A language for syntax highlighting, ie one of "python", "r", "yaml", "markdown", "text", "auto"
#' @param imgur A logical, should the image also be uploaded to imgur.
#' @param width a number, indicating the width in pixels for screenshot
#' @param drop_shadow Logical indicating whether to include drop shadow for the screenshot.
#' @param width_auto_adjust Logical indicating whether to auto adjust the width for better code-printing
#' @import glue chromote
#' @return Saves an image to disk and optionally returns the uploaded imgur URL
#' @export

gist_to_carbon <- function(
  gist_id, file = "code.png",
  bg = getOption("gistillery.bg", default = "#4A90E2"),
  theme = getOption("gistillery.theme", default = "night-owl"),
  font = getOption("gistillery.font", default = "Hack"),
  lang = "auto",
  imgur = TRUE,
  drop_shadow = TRUE,
  width = 680,
  width_auto_adjust = TRUE) {

  # currently available fonts/themes/langs
  fonts <- gistillery::carbon_fonts
  themes <- gistillery::carbon_themes
  langs <- c("python", "r", "yaml", "markdown", "text", "auto", "sql", "dockerfile", "javascript", "julia", "shell", "css", "htmlmixed")

  if (!(nchar(bg) == 7 && grepl("#", bg))) stop("The background must be a 6 unit hex value preceded by #, like #4A90E2", call. = FALSE)
  if (!(lang %in% langs)) stop(paste("Language must be one of", langs), call. = FALSE)
  if (!(theme %in% themes)) stop(paste("Theme must be one of the ones found in `carbon_themes`."), call. = FALSE)
  if (!(font %in% fonts)) stop(paste("Font must be one of the ones found in `carbon_fonts`."), call. = FALSE)

  bcol <- grDevices::col2rgb(bg)
  # convert to their RGBA format, dropping the various components
  # into their correct boxes - also note that alpha is on a 0 to 1 scale
  bg_txt <- glue::glue("rgba%28{bcol[1]}%2C{bcol[2]}%2C{bcol[3]}%2C{1}%29")

  drop_shadow <- if (isTRUE(drop_shadow)) {
    "&ds=true&dsyoff=20px&dsblur=68px"
  } else if (identical(drop_shadow, FALSE)) {
    "&ds=false"
  } else if (length(drop_shadow) > 0) {
    ds_values <- c(20, 68)
    for (i in seq_along(drop_shadow)) ds_values[i] <- drop_shadow[i]
    glue::glue("&ds=true&dsyoff={ds_values[1]}px&dsblur={ds_values[2]}px")
  } else {
    "&ds=false"
  }

  width_auto_adjust <- if (isTRUE(width_auto_adjust)) "true" else "false"

  carbon_query <- glue::glue("bg={bg_txt}&t={theme}&fm={font}&lang={lang}{drop_shadow}&width={width}&wa={width_auto_adjust}")
  carbon_url <- glue::glue("https://carbon.now.sh/embed/{gist_id}?{carbon_query}")
  cli::cli_alert_success("Carbon.now.sh used {.url {carbon_url}}")

  b <- chromote::ChromoteSession$new(
    # set the screen size to avoid clipped code
    width = width * 1.5,
    height = width * 10
  )
  on.exit(b$close())

  # Navigate to carbon url
  b$Page$navigate(carbon_url)
  b$Page$loadEventFired()
  # Enable background transparency in the screenshot
  b$Emulation$setDefaultBackgroundColorOverride(color = list(r = 0, g = 0, b = 0, a = 0))
  # Hide the copy button
  b$Runtime$evaluate("document.querySelector('.copy-button').style.display = 'none'")
  # Screenshot time!
  b$screenshot(filename = file, selector = "#export-container", scale = 3)

  if (!imgur) {
    return(file)
  }

  imgur_url <- as.character(imgur_upload(file))

  gist_append_img(imgur_url = imgur_url, gist_id = gist_id)
  cli::cli_alert_info("imgur url added to {.field {gist_id}}")
  cli::cli_alert_success("imgur link at {.url {imgur_url}}")
}


#' Add imgur-hosted URL to existing gist as a "comment" to bottom of script.
#'
#' @param imgur_url Existing URL from imgur, typically as created with gistillery::gist_to_carbon()
#' @param gist_id Unique ID for an existing Github Gist - this is where the comment will be added.
#' @import glue
#' @return Adds a commented line to bottom of existing Gist code
#' @export
gist_append_img <- function(imgur_url, gist_id = NULL) {

  req_gist <- "https://api.github.com" %>%
    httr2::request() %>%
    httr2::req_url_path_append("gists") %>%
    httr2::req_url_path_append(gist_id) %>%
    httr2::req_headers(
      Authorization = git_auth(),
      "User-Agent" = "gistr",
      Accept = "application/vnd.github.v3+json"
    )

  gist_resp <- httr2::req_perform(req_gist)

  gist_content_raw <- resp_body_json(gist_resp)

  gist_name <- names(gist_content_raw[["files"]])[1]

  gist_extract <- gist_content_raw[["files"]][[gist_name]]

  # get the raw code
  gist_content <- gist_extract[["content"]]

  # populate the imgur link into added text
  content_plus_comment <- glue::glue("{gist_content}\n# Code image at: ![]({imgur_url})\n\n")

  # rename the element with gist_name
  comment_body <- list(
    files = list(gist_name = list(content = content_plus_comment))
  )
  names(comment_body$files) <- gist_name

  # build the request
  req_update <- req_gist %>%
    httr2::req_body_json(comment_body) %>%
    httr2::req_method("PATCH")

  # send the add url request
  gist_with_url <- httr2::req_perform(req_update)

  }

#' Carbon themes
#'
#' A list of available themes supported by Carbon.
#'
#' Sourced from <https://github.com/carbon-app/carbon/blob/main/lib/constants.js>
#'
#' @examples {
#' carbon_themes
#' }
"carbon_themes"

#' Carbon fonts
#'
#' A list of available fonts that carbon supports.
#'
#' Sourced from: <https://github.com/carbon-app/carbon/blob/main/lib/constants.js>
#'
#' @examples {
#' carbon_fonts
#' }
"carbon_fonts"
