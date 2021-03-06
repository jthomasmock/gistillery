# gistillery <a href="https://jthomasmock.github.io/gistillery"><img src="man/figures/logo.png" align="right" height="135" /></a>

<!-- badges: start -->

<!-- badges: end -->

The goal of `gistillery` is to make it outrageously simple to take local code, send it to a [Github gist](https://gist.github.com/), get a beautiful image from [Carbon.now.sh](https://carbon.now.sh/), and make it ready to share!

Other packages that operate in the same space:

-   [`gistr`](https://github.com/ropensci/gistr) from ROpenSci - it provides a powerful and general interface to Gists. I have taken a different approach internally with `httr2`, but inspired by this interface.  
-   [`gistfo`](https://github.com/MilesMcBain/gistfo) from Miles McBain/Garrick Aden-Buie, this is a usefully opinionated "Get It Somewhere The F\*\*\* Online" package. I also adapted some concepts from this package..  
-   [`carbonate`](https://github.com/yonicd/carbonate) from Jonathan Sidi. A robust approach to a similar problem. `carbonate` uses R6 classes (object-oriented programming) and RSelenium. Rather than using `RSelenium`, `gistillery` uses `webshot2` to take a screenshot of the code with `chromote`.
-   [`carbonace`](https://github.com/yonicd/carbonace) from Jonathan Sidi. "A shiny app that converts the ace editor as high resolution images to share". This package provides a nice, local-only, offline ability to screenshot.

The difference in `{gistillery}` from the above packages is the intention to have both a Github Gist and a screenshot. `gistr` allows for uploading Gists but no screenshots, `gistfo` takes an entire file/text selection and uploads to gist and then to Carbon, but doesn't take programmatic screenshots. `carbonate`/`carbonace` take screenshots via Carbon/Ace but don't have a Gist component.

When sharing screenshots of code I believe it is vitally important to include a copy-pasteable/screen reader friendly option, thus `{gistillery}` requires a Gist to be created or an existing Gist to be used for taking screenshots. You can then include a link to the Gist wherever the screenshot goes, whether Twitter, LinkedIn, a personal website, or some other location. The other packages are still awesome - this is just a slightly different approach.

## Installation

You can install the development version of gistillery from [GitHub](https://github.com/) with:

``` r
# install.packages("remotes")
remotes::install_github("jthomasmock/gistillery")
```

## Core Workflow

There are three core functions, providing three steps in the process. Take code and upload to a Gist, take a screenshot of it, and then add a image url to the Gist. Importantly, all the steps are not *required* to be completed via this workflow. You can take existing Gists and use components of these functions rather than having to stick to the end-to-end workflow.

Please note that for Github Authentication which is required to affect your Gists, you'll need to reference the [`gistr` docs](https://docs.ropensci.org/gistr/reference/gist_auth.html)

> Generate a personal access token with the gist scope selected, and set it as the GITHUB_PAT environment variable per session using Sys.setenv or across sessions by adding it to your .Renviron file or similar. See <https://help.github.com/articles/creating-an-access-token-for-command-line-use> for help

### Step 1

We can use `gist_upload()` to take code from a file (via `readLines`), from a `reprex`/clipboard via `clipr::read_clip()`, or from a unsaved file via `rstudioapi`. Note that it also attaches the Gist URL to the bottom of the code snippet, so when you eventually share the code as an image people can still access copy-pastable code! (This is borrowed from `gistfo`, not an original idea)

``` r
# Load the functions
library(gistillery)
```

``` r
# this will use rstudioapi to take ALL the code from the currently
# highlighted file inside RStudio
# Workflow similar to core gistfo

gist_upload(content = NULL, gist_name = "unsaved15.R")
```

``` r
# We can take an existing file, and throw it up as a Gist quickly
gist_upload(content = readLines("mylocal-file.R"), gist_name = "local-file.R")

# Or we can take some code from the clipboard
gist_upload(content = clipr::read_clip(), gist_name = "copy-pasted-code.R")
# or even a reprex
gist_upload(reprex::reprex_r(), gist_name = "test-prex.R")

# or save the reprex to an object first
test_reprex <- reprex::reprex()
gist_upload(test_reprex, gist_name = "reprex-object.R")
```

### Step 2

Regardless of *how* you got the code to a Gist, you can then move on to step 2 and get the code over to [carbon.now.sh](https://carbon.now.sh) for beautiful screenshots. It takes the unique id for a Gist and then returns a lovely screenshot. Note that if you want to share that screenshot it also appends the gist URL to the bottom of the image. You should also include alt-text linking out to the Gist!

``` r
# core workflow
# specify the gist id to get code from
# specify the name of the output png
gist_to_carbon(
  gist_id = "17adcd1a401bec0e41cbd671048ff0b4", 
  file = "my-screenshot.png"
  )
```

![A screenshot of code, with the full code available at: <https://gist.github.com/jthomasmock/17adcd1a401bec0e41cbd671048ff0b4>](https://i.imgur.com/CwhrqKy.png)

If you want to go further with customization, you can change the background color with `bg`, the code theme with `theme`, the monospace font with `font`, the programming language with `lang` and optionally turn on/off the "upload to Imgur" feature. The `imgur=TRUE` option will give you an immediate URL so that you can embed the code elsewhere without having to actually upload the full image again.

You can also set some of these parameters via `options` like so: `options(gistillery.bg = "#d3d3d3", gistillery.theme = "cobalt", gistillery.font = "Fira+Code")`

### Step 3

Now that you have a local image and the Imgur link, you can use the third function. `add_gist_img` will take an existing gist and append the Imgur link to the code itself, that way you can programmatically add the screenshot URL back to your specific Gists.

``` r
gist_append_img(
  imgur_url = "https://i.imgur.com/UEkGyx7.png", 
  gist_id = "17adcd1a401bec0e41cbd671048ff0b4"
  )
```

Alternatively, you can use the Imgur link to include your code in places where it's inconvenient to use local image files or when you can't format code properly.

You can also use `gist_comment()` to upload a markdown-styled image into the comments of an existing Gist, like below:

``` r
gist_comment(gist_id, "![](some-valid-imgur-url.png)")
```

That will add a comment to the existing gist, adding a markdown image.

### Step N + 1

Now for the next step, you may want to post it to Twitter or somewhere else. My ask is that you use alt-text and link out to Github so that you can both assist screen-reader users and folks who just want to copy-paste your code!

As of 2022-05-09, you can use the GitHub version of `rtweet::post_tweet()` to post tweets, images, and alt-text.

IE:

``` r
rtweet::post_tweet(
  status = "My cool code screenshot",
  media = "my-screenshot.png",
  media_alt_text = "This is a screenshot of some R code. The code is available at https://gist.github.com/jthomasmock/17adcd1a401bec0e41cbd671048ff0b4. I have also copy-pasted the code below:
  
  # core workflow
  gist_to_carbon(
    gist_id = '17adcd1a401bec0e41cbd671048ff0b4', 
    file = 'my-screenshot.png'
  )
  "
)
```

### `reprex_shot()`

The last function, `reprex_shot()` is more of a local workflow. Calling this function will execute `reprex::reprex()` and then save the HTML to an image on disk. This is fine if you want to quickly get a local screenshot but it will not have the gist url attached to the screenshot.

``` r
reprex_shot(filename = "my-local-reprex.png")
```

### Altogether

If you wanted, you could used a pipe based workflow to get a seamless `reprex` -\> upload to Gist -\> screenshot from Carbon.

``` r
reprex::reprex_r() |> 
  gistillery::gist_upload(gist_name = "new-test-reprex.R") |> 
  gistillery::gist_to_carbon(file = "new-test-reprex.png") 
```
