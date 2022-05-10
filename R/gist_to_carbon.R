#' Take an existing gist, send to carbon, and save the image locally
#'
#' @param gist_id the unique id for your existing gist
#' @param file the name of the file for printing, eg code.png
#' @param bg A valid hex code for color, ie #D3D3D3
#' @param theme A valid theme, ie one of "cobalt", "nord", "seti", "night-owl", "monokai", "material", "vscode", "verminal", "synthwave-84", "shades-of-purple"
#' @param font A character string for font, one of "IBM+Plex+Mono", "Hack", "Fira+Code", "Source+Code+Pro"
#' @param lang A language for syntax highlighting, ie one of "python", "r", "yaml", "markdown", "text", "auto"
#' @param imgur A logical, should the image also be uploaded to imgur.
#' @inheritDotParams webshot2::webshot
#' @import glue
#' @importFrom knitr imgur_upload
#' @importFrom webshot2 webshot
#' @return Saves an image to disk and optionally returns the uploaded imgur URL
#' @export

gist_to_carbon <- function(gist_id, file = "code.png", bg = "#4A90E2",
                           theme = "shades-of-purple", font = "Fira+Code",
                           lang = "auto", imgur = TRUE, ...) {
  fonts <- c("IBM+Plex+Mono", "Hack", "Fira+Code", "Source+Code+Pro")
  langs <- c("python", "r", "yaml", "markdown", "text", "auto")
  themes <- c("cobalt", "nord", "seti", "night-owl", "monokai", "material", "vscode", "verminal", "synthwave-84", "shades-of-purple")

  if (!(nchar(bg) == 7 && grepl("#", bg))) stop("The background must be a 6 unit hex value preceded by #, like #4A90E2", call. = FALSE)
  if (!(lang %in% langs)) stop(paste("Language must be one of", langs), call. = FALSE)
  if (!(theme %in% themes)) stop(paste("Theme must be one of", themes), call. = FALSE)
  if (!(font %in% fonts)) stop(paste("Font must be one of", fonts), call. = FALSE)

  bcol <- grDevices::col2rgb(bg)
  bg_txt <- glue::glue("rgba%28{bcol[1]}%2C{bcol[2]}%2C{bcol[3]}%2C{1}%29")

  carbon_query <- glue::glue("bg={bg_txt}&t={theme}&fm={font}&lang={lang}")
  carbon_url <- glue::glue("https://carbon.now.sh/embed/{gist_id}?{carbon_query}")

  # save to disk
  webshot2::webshot(url = carbon_url, file = file, zoom = 3, ...)
  # upload to imgur
  if (imgur) {
    imgur_url <- as.character(knitr::imgur_upload(file))
    return(imgur_url)
  }
}


#' Add imgur-hosted URL to existing gist as a "comment" to bottom of script.
#'
#' @param imgur_url Existing URL from imgur, typically as created with tomtom::gist_to_carbon
#' @param gist_id Unique ID for an existing Github Gist
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

