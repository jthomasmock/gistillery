#' Carbon fonts and themes
#' via: https://github.com/carbon-app/carbon/blob/main/lib/constants.js

library(tibble)
library(dplyr)
library(tidyr)
library(stringr)

raw_constants <- tibble::tibble(
  x = readLines("https://github.com/carbon-app/carbon/raw/main/lib/constants.js")
) |>
  mutate(constant_name = str_match(x,"export const ([A-Z]+)")[,2]) |>
  fill(constant_name)

carbon_fonts <- raw_constants |>
  filter(constant_name == "FONTS") |>
  mutate(font_id = str_match(x,"id\\: ['|\"](.+)['|\"],")[,2]) |>
  filter(!is.na(font_id)) |>
  pull(font_id) |>
  str_replace_all(" ","+")

carbon_themes <- raw_constants |>
  filter(constant_name == "THEMES") |>
  mutate(theme_id = str_match(x,"id\\: ['|\"](.+)['|\"],")[,2]) |>
  filter(!is.na(theme_id)) |>
  pull(theme_id)

carbon_langs <- raw_constants |>
  filter(constant_name == "LANGUAGES") |>
  mutate(language_id = str_match(x,"mode\\: ['|\"](.+)['|\"],")[,2]) |>
  filter(!is.na(language_id)) |>
  pull(language_id) |>
  unique() |>
  sort()

usethis::use_data(carbon_fonts, carbon_themes)
