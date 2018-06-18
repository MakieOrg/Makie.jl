Pkg.add("Vega")
using Vega

#see also: https://vega.github.io/editor/#/examples/vega/word-cloud

corpus = [
"Julia is a high-level, high-performance dynamic programming language for technical computing, with syntax that is familiar to users of other technical computing environments. It provides a sophisticated compiler, distributed parallel execution, numerical accuracy, and an extensive mathematical function library. Julia’s Base library, largely written in Julia itself, also integrates mature, best-of-breed open source C and Fortran libraries for linear algebra, random number generation, signal processing, and string processing. In addition, the Julia developer community is contributing a number of external packages through Julia’s built-in package manager at a rapid pace. IJulia, a collaboration between the IPython and Julia communities, provides a powerful browser-based graphical notebook interface to Julia.",
"Julia programs are organized around multiple dispatch; by defining functions and overloading them for different combinations of argument types, which can also be user-defined. For a more in-depth discussion of the rationale and advantages of Julia over other systems, see the following highlights or read the introduction in the online manual."
]

corpus2 = ["2d", "mesh", "polygon", "2d", "scatter", "image", "subscene", "2d",
"contour", "Anthony", "2d", "contour", "2d", "contour", "2d", "heatmap", "updating",
"2d", "scatter", "animation", "2d", "text", "align", "rotation", "2d", "text",
"scatter", "3d", "similar", "animated", "meshscatter", "axi s", "mesh", "3d",
"views", "scatter", "axis", "lines", "3d", "meshscatter", "3d", "animated",
"video", "axis", "wireframe", "3d", "surface", "mesh", "cat", "3d", "linesegment",
"mesh", "3d", "glow", "scatter", "3d", "scatter", "axis", "marker", "3d", "animated",
"offset", "lines", "3d", "gif", " axis", "3d", "surface", "text", "volume", "3d",
"documentation", "2d", "heatmap", "documentation", "mesh", "cat", "3d",
"documentation", "texture", "mesh", "cat", "3d", "documentation", "axis",
"mesh", "3d", "documentation", "mesh", "cat", "wireframe", "3d", "documentation",
"wireframe", "3d", " documentation", "wireframe", "3d", "documentation", "surface",
"3d", "documentation", "surface", "image", "3d", "documentation", "surface", "2d",
"lines", "documentation", "meshscatter", "3d", "documentation", "2d", "scatter",
"documentation", "Makie.scatter", "Anthony", "2d", "scatter", "docume ntation",
"Makie.scatter", "Anthony", "2d", "scatter", "documentation", "2d", "scatter",
"VideoStream", "documentation", "linesegment", "scatter", " lines", "3d",
"documentation", "linestyle", "legend", "colorlegend", "2d", "documentation",
"legend", "meshscatter", "3d", "documentation", "VideoStream", "linesegment",
"slices", "volume", "3d layout", "heatmap", "documentation", "layout", "contour",
"slices", "volume", "gui", "animation", "documentation", "layout"]

wc = wordcloud(x = corpus2)
colorscheme!(wc, palette = ("Spectral", 11))
