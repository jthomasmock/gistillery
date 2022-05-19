#' Execute a reprex::reprex() and take a local screenshot of the reprex output
#' @description reprex_shot() will first take a reprex and then capture the
#' HTML output into an on-disk image, optionally uploading the image to Imgur.
#' @param filename a filename, ending in .png
#' @param open_file A logical, should the file be opened once saved
#' @param imgur A logical, should the image be uploaded to imgur also
#' @param ... additional arguments passed to reprex::reprex()
#' @return a screenshot of the reprex on disk
#' @importFrom reprex reprex
#' @import cli
#' @importFrom webshot2 webshot
#' @export
reprex_shot <- function(filename = NULL, ..., open_file = TRUE,
                        imgur = FALSE) {
  reprex::reprex(...)

  # get tempfiles
  temp_fs <- dir(tempdir(), full.names = TRUE)
  reprex_fs <- temp_fs[grepl(x = temp_fs, pattern = "reprex_preview.html")]

  # check for missing reprex
  if (identical(character(0), reprex_fs)) stop("No reprex found. Run reprex() on some code.")

  # get tempfile times
  time_fs <- file.info(reprex_fs)$ctime

  # grab the latest reprex
  temp_reprex <- reprex_fs[time_fs == max(time_fs)]

  # check for missing reprex
  if (is.na(temp_reprex)) stop("No reprex found. Run reprex() on some code.")

  if (is.null(filename)) {
    filename <- basename(temp_reprex)
    filename <- paste0(gsub(x = filename, pattern = "_reprex_preview.html", replacement = ""), ".png")
  }
  webshot2::webshot(temp_reprex, file = filename, zoom = 3)
  cli::cli_alert_success("Screenshot saved as {.path {filename}}.")

  # print number of lines, a basic output so that you can
  # pipe reprex::reprex() directly into reprex_shot()
  cli::cli_alert_info("Used most recent reprex {.field {max(time_fs)}} at {.path {temp_reprex}}")

  # optionally auto-open new file
  if (open_file) rstudioapi::viewer(filename)

  # optionally upload to imgur
  if (imgur) {
    imgur_out <- imgur_upload(filename)

    cli::cli_alert_success("Screenshot uploaded to {.url {as.character(imgur_out)}}")
  }
}

#' @importFrom utils packageVersion
# vendored from knitr
# https://github.com/yihui/knitr/blob/3237add034368a3018ff26fa9f4d0ca89a4afd78/R/utils-upload.R#L37-L51
imgur_upload <- function(file) {
  key <- "9f3460e67f308f6"
  if (!is.character(key)) {
    stop("The Imgur API Key must be a character string!")
  }
  resp <- httr::POST("https://api.imgur.com/3/image.xml", config = httr::add_headers(Authorization = paste(
    "Client-ID",
    key
  )), body = list(image = httr::upload_file(file)))
  httr::stop_for_status(resp, "upload to imgur")
  res <- httr::content(resp, as = "raw")
  res <- if (length(res)) {
    xml2::as_list(xml2::read_xml(res))
  }
  if (utils::packageVersion("xml2") >= "1.2.0") {
    res <- res[[1L]]
  }
  if (is.null(res$link[[1]])) {
    stop("failed to upload ", file)
  }
  structure(res$link[[1]], XML = res)
}
