library(magick)
library(dplyr)

url <- "https://m.media-amazon.com/images/I/61qtsKcMz6L._AC_SL1001_.jpg"

raw_octo <- "https://freesvg.org/img/Kid-Octopi-Redrawn.png" |> image_read()
raw_img <- magick::image_read(url)

octo_pixel <- raw_octo |>
  image_scale("10%") |>
  image_scale("1000%") |>
  image_scale("45%")

pot_pixel <- raw_img |>
  magick::image_scale("8%") |>
  magick::image_scale("1000%")
?image_flatten(c(pot_pixel, octo_pixel))

image_combo <- image_composite(pot_pixel, octo_pixel, offset = "+325+165") |>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+88+550") |>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+92+550")|>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+90+552")|>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+90+548") |>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+86+550") |>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+94+550")|>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+90+554")|>
  image_annotate("gistillery", font = 'Fira Code',
    color = "black",
    size = 85, location = "+90+546") |>
  image_annotate("gistillery", font = 'Fira Code',
    color = "white",
    size = 85, location = "+90+550")

image_combo |>
  image_write("gistillery-logo.png")
