@def title = "Getting Started with Contributing"
@def order = 0
@def frontpage = false
@def description = "Some guidance and advice on how to contribute to Makie"

## Conversion of Data To Internal Pixel Dimensions

I couldn't find any direct docs on it but https://github.com/MakieOrg/Makie.jl/pull/3226#issuecomment-1885218337 is probably a good read
Basically there are the "world" or "input space" or "data space" coordinates that you input to a plot, which get multiplied by 4x4 matrices to go into "pixel space"
(there are some intermediate steps depending on backend)
and pixel space is directly addressed to that cell of the 2d array which holds the colors of the eventual image shown on screen
