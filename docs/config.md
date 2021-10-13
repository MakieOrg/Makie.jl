<!--
Add here global page variables to use throughout your website.
-->
+++
author = "Makie.jl"
mintoclevel = 2

# Add here files or directories that should be ignored by Franklin, otherwise
# these files might be copied and, if markdown, processed by Franklin which
# you might not want. Indicate directories by ending the name with a `/`.
# Base files such as LICENSE.md and README.md are ignored by default.
ignore = ["node_modules/", "misc/"]

# RSS (the website_{title, descr, url} must be defined to get RSS)
generate_rss = true
website_title = "Franklin Template"
website_descr = "Example website using Franklin"
prepath = get(ENV, "PREVIEW_FRANKLIN_PREPATH", "")
website_url = get(ENV, "PREVIEW_FRANKLIN_WEBSITE_URL", "makie.juliaplots.org")
+++

<!--
Add here global latex commands to use throughout your pages.
-->
\newcommand{\R}{\mathbb R}
\newcommand{\scal}[1]{\langle #1 \rangle}

<!-- myreflink{Basic Tutorial} expands to [Basic Tutorial](link_to_that) -->
\newcommand{\myreflink}[1]{[!#1](\reflink{!#1})}
