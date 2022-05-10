#' Take a local screenshot of reprex output
#' @param code Optional code from a reprex, mainly here so that you can pipe reprex directly into this function.
#' @param filename a filename, ending in .png
#' @param open_file A logical, should the file be opened once saved
#' @param imgur A logical, should the image be uploaded to imgur also
#' @return a screenshot of the reprex on disk
#' @export
reprex_shot <- function(code = NULL, filename = NULL, open_file = TRUE,
  imgur = FALSE){

  # get tempfiles
  temp_fs <- dir(tempdir(), full.names = TRUE)
  # get tempfile times
  time_fs <- file.info(temp_fs)$ctime

  # sort tempfiles
  temp_sort <- temp_fs[order(desc(time_fs))]
  # get first element matching the reprex_preview
  temp_reprex <- temp_sort[grepl(x = temp_sort, pattern = "reprex_preview.html")][1]
  if(is.null(filename)){
    filename <- basename(temp_reprex)
    filename <- paste0(gsub(x = filename, pattern = "_reprex_preview.html", replacement = ""), ".png")
  }
  webshot2::webshot(temp_reprex, file = filename)
  cli::cli_alert_success("Screenshot saved at {.path {filename}}.")

  # print number of lines, a basic output so that you can
  # pipe reprex::reprex() directly into reprex_shot()
  if(!is.null(code)) cli::cli_alert_info("reprex code had {length(code)} lines.")

  # optionally auto-open new file
  if(open_file) rstudioapi::viewer(filename)

  # optionally upload to imgur
  if(imgur) {
    imgur_out <- knitr::imgur_upload(filename)

    cli::cli_alert_success("Screenshot uploaded to {.url {as.character(imgur_out)}}")
  }
}

