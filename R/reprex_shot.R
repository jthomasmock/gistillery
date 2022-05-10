#' Take a local screenshot of reprex output
#' @param code Optional code from a reprex, mainly here so that you can pipe reprex directly into this function.
#' @param filename a filename, ending in .png
#' @param open_file A logical, should the file be opened once saved
#' @param imgur A logical, should the image be uploaded to imgur also
#' @return a screenshot of the reprex on disk
#' @export
reprex_shot <- function(code = NULL, filename = NULL, open_file = TRUE,
                        imgur = FALSE) {

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
  if (!is.null(code)) {
    cli::cli_alert_info("reprex code had {length(code)} lines")
  } else {
    cli::cli_alert_info("Used most recent reprex {.field {max(time_fs)}} at {.path {temp_reprex}}")
  }

  # optionally auto-open new file
  if (open_file) rstudioapi::viewer(filename)

  # optionally upload to imgur
  if (imgur) {
    imgur_out <- knitr::imgur_upload(filename)

    cli::cli_alert_success("Screenshot uploaded to {.url {as.character(imgur_out)}}")
  }
}
