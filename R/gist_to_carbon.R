#' Take an existing gist, send to carbon, and save the image locally
#'
#' @param gist_id the unique id for your existing gist, can be piped from gist_upload() or passed manually.
#' @param file the name of the file for printing, eg code.png
#' @param bg A valid hex code for color, ie #D3D3D3
#' @param theme A valid theme, ie one of "cobalt", "nord", "seti", "night-owl", "monokai", "material", "vscode", "verminal", "synthwave-84", "shades-of-purple"
#' @param font A character string for font, one of "IBM+Plex+Mono", "Hack", "Fira+Code", "Source+Code+Pro"
#' @param lang A language for syntax highlighting, ie one of "python", "r", "yaml", "markdown", "text", "auto"
#' @param imgur A logical, should the image also be uploaded to imgur.
#' @param width a number, indicating the width in pixels for screenshot
#' @param drop_shadow Logical indicating whether to include drop shadow for the screenshot.
#' @param width_auto_adjust Logical indicating whether to auto adjust the width for better code-printing
#' @import glue chromote
#' @importFrom knitr imgur_upload
#' @return Saves an image to disk and optionally returns the uploaded imgur URL
#' @export

gist_to_carbon <- function(gist_id, file = "code.png", bg = "#4A90E2",
                           theme = "night-owl", font = "Hack",
                           lang = "auto", imgur = TRUE,
                           drop_shadow = TRUE,
                           width = 680,
                           width_auto_adjust = TRUE) {
  fonts <- c("IBM+Plex+Mono", "Hack", "Fira+Code", "Source+Code+Pro")
  langs <- c("python", "r", "yaml", "markdown", "text", "auto")
  themes <- c(
    "cobalt", "nord", "seti", "night-owl", "monokai", "hopscotch", "twilight",
    "material", "vscode", "verminal", "synthwave-84", "shades-of-purple"
  )

  if (!(nchar(bg) == 7 && grepl("#", bg))) stop("The background must be a 6 unit hex value preceded by #, like #4A90E2", call. = FALSE)
  if (!(lang %in% langs)) stop(paste("Language must be one of", langs), call. = FALSE)
  if (!(theme %in% themes)) stop(paste("Theme must be one of", themes), call. = FALSE)
  if (!(font %in% fonts)) stop(paste("Font must be one of", fonts), call. = FALSE)

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

  imgur_url <- as.character(knitr::imgur_upload(file))

  gist_append_img(imgur_url = imgur_url, gist_id= gist_id)
  cli::cli_alert_info("imgur url added to {.field {gist_id}}")
  cli::cli_alert_success("imgur link at {.url {imgur_url}}")
}


#' Add imgur-hosted URL to existing gist as a "comment" to bottom of script.
#'
#' @param imgur_url Existing URL from imgur, typically as created with gistillery::gist_to_carbon()
#' @param gist_id Unique ID for an existing Github Gist - this is where the comment will be added.
#' @import gistr glue
#' @return Adds a commented line to bottom of existing Gist code
#' @export
gist_append_img <- function(imgur_url, gist_id = NULL) {
  base_gist <- gistr::gist(gist_id)
  gist_url <- base_gist$html_url

  # temp add file
  gist_id_file <- file.path(tempdir(), base_gist$files[[1]]$filename)

  # populate the imgur link into added text
  comment <- glue::glue("\n\n# Code image at: ![]({imgur_url})\n\n")

  # Overwrite file with content, new comment
  cat(base_gist$files[[1]]$content, comment, file = gist_id_file)
  # update local gist
  updated_gist <- gistr::update_files(base_gist, gist_id_file)
  # push to GitHub gist
  gistr::update(updated_gist)

  # cleanup/remove file
  rm(gist_id_file)
}
