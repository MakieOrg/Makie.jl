# WGLMakie

[WGLMakie](https://github.com/JuliaPlots/Makie.jl/tree/master/WGLMakie) is the Web-based backend, and is still experimental (though relatively feature-complete). WGLMakie uses [JSServe](https://github.com/SimonDanisch/JSServe.jl) to generate the HTML and JS for the Makie plots.


## Activation

Activate the backend by calling `WGLMakie.activate!()` with the following options:
```julia:docs
# hideall
using WGLMakie, Markdown
println("~~~")
println(Markdown.html(@doc WGLMakie.activate!))
println("~~~")
```
\textoutput{docs}

## Output

You can use JSServe and WGLMakie in Pluto, IJulia, Webpages and Documenter to create interactive apps and dashboards, serve them on live webpages, or export them to static HTML.

This tutorial will run through the different modes and what kind of limitations to expect.

First, one should use the new Page mode for anything that displays multiple outputs, like Pluto/IJulia/Documenter.
This creates a single entry point, to connect to the Julia process and load dependencies.
For Documenter, the page needs to be set to `exportable=true, offline=true`.
Exportable has the effect of inlining all data & js dependencies, so that everything can be loaded in a single HTML object.
`offline=true` will make the Page not even try to connect to a running Julia
process, which makes sense for the kind of static export we do in Documenter.


\begin{showhtml}{}
```julia
using JSServe, Markdown
Page(exportable=true, offline=true)
```
\end{showhtml}

After the page got displayed by the frontend, we can start with creating plots and JSServe Apps:


\begin{showhtml}{}
```julia
using WGLMakie
WGLMakie.activate!()
scatter(1:4, color=1:4)
```
\end{showhtml}


As you can see, the output is completely static, because we don't have a running Julia server, as it would be the case with e.g. Pluto.
To make the plot interactive, we will need to write more parts of WGLMakie in JS, which is an ongoing effort.
As you can see, the interactivity already keeps working for 3D:

\begin{showhtml}{}
```julia
N = 60
function xy_data(x, y)
    r = sqrt(x^2 + y^2)
    r == 0.0 ? 1f0 : (sin(r)/r)
end
l = range(-10, stop = 10, length = N)
z = Float32[xy_data(x, y) for x in l, y in l]
surface(
    -1..1, -1..1, z,
    colormap = :Spectral
)
```
\end{showhtml}

There are a couple of ways to keep interacting with Plots in a static export.

## Record a statemap

JSServe allows to record a statemap for all widgets, that satisfy the following interface:

```julia
# must be true to be found inside the DOM
is_widget(x) = true
# Updating the widget isn't dependant on any other state (only thing supported right now)
is_independant(x) = true
# The values a widget can iterate
function value_range end
# updating the widget with a certain value (usually an observable)
function update_value!(x, value) end
```

Currently, only sliders overload the interface:

\begin{showhtml}{}
```julia
using Observables

App() do session::Session
    n = 10
    index_slider = Slider(1:n)
    volume = rand(n, n, n)
    slice = map(index_slider) do idx
        return volume[:, :, idx]
    end
    fig = Figure()
    ax, cplot = contour(fig[1, 1], volume)
    rectplot = linesegments!(ax, Rect(-1, -1, 12, 12), linewidth=2, color=:red)
    on(index_slider) do idx
        translate!(rectplot, 0,0,idx)
    end
    heatmap(fig[1, 2], slice)
    slider = DOM.div("z-index: ", index_slider, index_slider.value)
    return JSServe.record_states(session, DOM.div(slider, fig))
end
```
\end{showhtml}

## Execute Javascript directly

JSServe makes it easy to build whole HTML and JS applications.
You can for example directly register javascript function that get run on change.

\begin{showhtml}{}
```julia
using JSServe: onjs

app = App() do session::Session
    s1 = Slider(1:100)
    slider_val = DOM.p(s1[]) # initialize with current value
    # call the `on_update` function whenever s1.value changes in JS:
    onjs(session, s1.value, js"""function on_update(new_value) {
        //interpolating of DOM nodes and other Julia values work mostly as expected:
        const p_element = $(slider_val)
        p_element.innerText = new_value
    }
    """)

    return DOM.div("slider 1: ", s1, slider_val)
end
```
\end{showhtml}

One can also interpolate plots into JS and update those via JS.
The problem is, that there isn't an amazing interface yet.
The returned object is directly a THREE object, with all plot attributes converted into Javascript types.
The good news is, all attributes should be in either `three_scene.material.uniforms`, or `three_scene.geometry.attributes`.
Going forward, we should create an API in WGLMakie, that makes it as easy as in Julia: `plot.attribute = value`.
But while this isn't in place, logging the the returned object makes it pretty easy to figure out what to do - btw, the JS console + logging is amazing and makes it very easy to play around with the object once logged.

\begin{showhtml}{}
```julia
using JSServe: onjs, evaljs, on_document_load

app = App() do session::Session
    s1 = Slider(1:100)
    slider_val = DOM.p(s1[]) # initialize with current value

    fig, ax, splot = scatter(1:4)

    # With on_document_load one can run JS after everything got loaded.
    # This is an alternative to `evaljs`, which we can't use here,
    # since it gets run asap, which means the plots won't be found yet.

    on_document_load(session, js"""
        const plots = $(splot)
        const scatter_plot = plots[0]
        // open the console with ctr+shift+i, to inspect the values
        // tip - you can right click on the log and store the actual variable as a global, and directly interact with it to change the plot.
        console.log(scatter_plot)
        console.log(scatter_plot.material.uniforms)
        console.log(scatter_plot.geometry.attributes)
    """)

    # with the above, we can find out that the positions are stored in `offset`
    # (*sigh*, this is because threejs special cases `position` attributes so it can't be used)
    # Now, lets go and change them when using the slider :)
    onjs(session, s1.value, js"""function on_update(new_value) {
        const plots = $(splot)
        const scatter_plot = plots[0]

        // change first point x + y value
        scatter_plot.geometry.attributes.offset.array[0] = (new_value/100) * 4
        scatter_plot.geometry.attributes.offset.array[1] = (new_value/100) * 4
        // this always needs to be set of geometry attributes after an update
        scatter_plot.geometry.attributes.offset.needsUpdate = true
    }
    """)
    # and for got measures, add a slider to change the color:
    color_slider = Slider(LinRange(0, 1, 100))
    onjs(session, color_slider.value, js"""function on_update(hue) {
        const plot = $(splot)[0]
        const color = new THREE.Color()
        color.setHSL(hue, 1.0, 0.5)
        plot.material.uniforms.color.value.x = color.r
        plot.material.uniforms.color.value.y = color.g
        plot.material.uniforms.color.value.z = color.b
    }""")

    markersize = Slider(1:100)
    onjs(session, markersize.value, js"""function on_update(size) {
        const plot = $(splot)[0]
        plot.material.uniforms.markersize.value.x = size
        plot.material.uniforms.markersize.value.y = size
    }""")
    return DOM.div(s1, color_slider, markersize, fig)
end
```
\end{showhtml}

This summarizes the current state of interactivity with WGLMakie inside static pages.

# Pluto/IJulia

Note that the normal interactivity from Makie is preserved with WGLMakie in e.g. Pluto, as long as the Julia session is running.
Which brings us to setting up Pluto/IJulia sessions! The return value of your first cell must be the return value of the function `Page`.
For example, your first cell can be

```julia
begin
	using JSServe
	Page()
end
```

As is common with files meant to be shared, you might wish to set up a temporary directory so as to not pollute other people's environment. The following code will also be a valid first cell.

```julia
begin
	using Pkg
	Pkg.activate(mktempdir())

	Pkg.add("JSServe")
	using JSServe
	Page()
end
```

If you're accessing the notebook from another PC, you must set:

```julia
begin
	using JSServe
	Page(listen_url="0.0.0.0")
end
```

For more advanced setups consult the `?Page` docs and `JSServe.configure_server!`.

## Styling

You may have noticed, styling isn't really amazing right now.
The good news is, that one can use the whole mighty power of the CSS/HTML universe.
If it wasn't clear so far, JSServe allows to load arbitrary css, and `DOM.xxx` wraps all existing HTML tags.

\begin{showhtml}{}
```julia
using Colors
using JSServe: rows

App() do session::Session

    hue_slider = Slider(0:360)
    color_swatch = DOM.div(class="h-6 w-6 p-2 m-2 rounded shadow")

    onjs(session, hue_slider.value, js"""function (hue){
        $(color_swatch).style.backgroundColor = "hsl(" + hue + ",60%,50%)"
    }""")

    return DOM.div(JSServe.TailwindCSS, rows(hue_slider, color_swatch))
end
```
\end{showhtml}

Tailwind is quite a amazing and has a great documentation especially for CSS beginners:
https://tailwindcss.com/docs/

Note, that JSServe.TailwindCSS is nothing but:

```julia
TailwindCSS = JSServe.Asset("/path/to/tailwind.min.css")
```

So any other CSS file can be used.

It's also pretty easy to make reusable blocks from styled elements.
E.g. the `rows` function above is nothing but:

```julia
rows(args...; class="") = DOM.div(args..., class=class * " flex flex-row")
```

It would be more correct to define it as:

```julia
rows(args...; class="") = DOM.div(JSServe.TailwindCSS, args..., class=class * " flex flex-row")
```

JSServe will then make sure, that `JSServe.TailwindCSS` is loaded, and will only load it once!

Finally, lets create a styled, reusable card componenent:

\begin{showhtml}{}
```julia
using Markdown

struct GridCard
    elements::Any
end

GridCard(elements...) = GridCard(elements)

function JSServe.jsrender(card::GridCard)
    return DOM.div(JSServe.TailwindCSS, card.elements..., class="rounded-lg p-2 m-2 shadow-lg grid auto-cols-max grid-cols-2 gap-4")
end

App() do session::Session
    # We can now use this wherever we want:
    fig = Figure(resolution=(200, 200))
    contour(fig[1,1], rand(4,4))
    card = GridCard(
        Slider(1:100),
        DOM.h1("hello"),
        DOM.img(src="https://julialang.org/assets/infra/logo.svg"),
        fig
    )
    # Markdown creates a DOM as well, and you can interpolate
    # arbitrary jsrender'able elements in there:
    return md"""

    # Wow, Markdown works as well?

    $(card)

    """
end
```
\end{showhtml}

Hopefully, over time there will be helper libraries with lots of stylised elements like the above, to make flashy dashboards with JSServe + WGLMakie.


# Export

Documenter just renders the plots + Page as html,
so if you want to inline WGLMakie/JSServe objects into your own page,
one can just use something like this:

```julia
using WGLMakie, JSServe

using WGLMakie, JSServe
WGLMakie.activate!()

open("index.html", "w") do io
    println(io, """
    <html>
        <head>
        </head>
        <body>
    """)
    # before doing anything else,
    # make sure the Page setup code gets rendered as HTML
    show(io, MIME"text/html"(), Page(exportable=true, offline=true))
    # Then, you can just inline plots or whatever you want :)
    show(io, MIME"text/html"(), scatter(1:4))
    show(io, MIME"text/html"(), surface(rand(4, 4)))
    # or anything else from JSServe, or that can be displayed as html:
    show(io, MIME"text/html"(), JSServe.Slider(1:3))
    println(io, """
        </body>
    </html>
    """)
end
```

# Troubleshooting

## Plots don't display in Safari

Safari users may need to [enable](https://discussions.apple.com/thread/8655829) WebGL.
