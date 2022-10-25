# Fonts

Makie uses the `FreeType.jl` package for font support, therefore, most fonts that this package can load should be supported by Makie as well.
Fonts can be selected in multiple different ways:

## String

If you pass a `String` as a font, this can either be resolved as a file name for a font file, or as the (partial) name of the font itself (font family plus style).
Font name matching is case insensitive and accepts partial matches.

```julia
font_by_path = "/some/path/to/a/font_file.ttf"
font_by_name = "TeX Gyre Heros Makie"
```

If you want to find out what exact font your string was resolved as, you can execute `Makie.to_font(the_string)`:

```julia:fonts1
using Makie
Makie.to_font("Blackchancery")
```
\show{fonts1}

## Symbol

A `Symbol` will be resolved by looking it up in the `text`'s `fonts` attribute.
The default theme has the following fonts set:

```julia:fonts2
using Makie
Makie.current_default_theme()[:fonts]
```
\show{fonts2}

Therefore, you can pick a font from this set by setting, for example, `font = :bold_italic`.
The advantage of this is that you can set your fonts not by hardcoding specific ones at every place where you use `text`, but by setting the fonts at the top level.

You can modify or add keys in the font set using `set_theme!`, `with_theme`, `update_theme!`, or by passing them to the `Figure` constructor.
Here's an example:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(fontsize = 24, fonts = (; regular = "Dejavu", weird = "Blackchancery"))
Axis(f[1, 1], title = "A title", xlabel = "An x label", xlabelfont = :weird)

f
```
\end{examplefigure}

## Emoji and color fonts

Currently, Makie does not have the ability to draw emoji or other color fonts.
This is due to the implementation of text drawing in GLMakie and WGLMakie, which relies on signed distance fields that can only be used to render monochrome glyphs, but not arbitrary bitmaps.
If you want to use emoji as scatter markers, consider using images (you will need to find suitable images separately, you cannot easily extract emoji from fonts with Makie).


