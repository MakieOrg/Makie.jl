# WGLMakie

[WGLMakie](https://github.com/MakieOrg/Makie.jl/tree/master/WGLMakie) is the web-based backend, which is mostly implemented in Julia right now.
WGLMakie uses [Bonito](https://github.com/SimonDanisch/Bonito.jl) to generate the HTML and JavaScript for displaying the plots. On the JavaScript side, we use [ThreeJS](https://threejs.org/) and [WebGL](https://en.wikipedia.org/wiki/WebGL) to render the plots.
Moving more of the implementation to JavaScript is currently the goal and will give us a better JavaScript API, and more interaction without a running Julia server.


!!! warning
    WGLMakie can be considered experimental because the JavaScript API isn't stable yet and the notebook integration isn't perfect yet, but all plot types should work, and therefore all recipes, but there are certain caveats



#### Browser Support


##### IJulia


* Bonito now uses the IJulia connection, and therefore can be used even with complex proxy setup without any additional setup
* reload of the page isn't supported, if you reload, you need to re-execute all cells and make sure that `Page()` is executed first.

#### JupyterHub / Jupyterlab / Binder


* WGLMakie should mostly work with a websocket connection. Bonito tries to [infer the proxy setup](https://github.com/SimonDanisch/Bonito.jl/blob/master/src/server-defaults.jl) needed to connect to the julia process. On local jupyterlab instances, this should work without problem. On hosted instances one will likely need to have [`jupyter-server-proxy`](https://jupyter-server-proxy.readthedocs.io/en/latest/arbitrary-ports-hosts.html#with-jupyterhub) installed, and then execute something like `Page(; listen_port=9091, proxy_url="<jhub-instance>.com/user/<username>/proxy/9091")`.

  Also see:
    * [issue #2464](https://github.com/MakieOrg/Makie.jl/issues/2464)
    * [issue #2405](https://github.com/MakieOrg/Makie.jl/issues/2405)


#### Pluto

* still uses Bonito's Websocket connection, so needs extra setup for remote servers.
* reload of the page isn't supported, if you reload, you need to re-execute all cells and make sure that `Page()` is executed first.
* static html export not fully working yet

#### JuliaHub

* VSCode in the browser should work out of the box.
* Pluto in JuliaHub still has a [problem](https://github.com/SimonDanisch/Bonito.jl/issues/140) with the WebSocket connection. So, you will see a plot, but interaction doesn't work.


#### Browser Support

Some browsers may have only WebGL 1.0, or need extra steps to enable WebGL, but in general, all modern browsers on [mobile and desktop should support WebGL 2.0](https://www.lambdatest.com/web-technologies/webgl2).
Safari users may need to [enable](https://discussions.apple.com/thread/8655829) WebGL, though.
If you end up stuck on WebGL 1.0, the main missing feature will be `volume` & `contour(volume)`.



## Activation and screen config

Activate the backend by calling `WGLMakie.activate!()` with the following options:
```@docs
WGLMakie.activate!
```

## Output

You can use Bonito and WGLMakie in Pluto, IJulia, Webpages and Documenter to create interactive apps and dashboards, serve them on live webpages, or export them to static HTML.

This tutorial will run through the different modes and what kind of limitations to expect.

### Page

`Page()` can be used to reset the Bonito state needed for multipage output like it's the case for `Documenter` or the various notebooks (IJulia/Pluto/etc).
Previously, it was necessary to always insert and display the `Page` call in notebooks, but now the call to `Page()` is optional and doesn't need to be displayed.
What it does is purely reset the state for a new multi-page output, which is usually the case for `Documenter`, which creates multiple pages in one Julia session, or you can use it to reset the state in notebooks, e.g. after a page reload.
`Page(exportable=true, offline=true)` can be used to force inlining all data & js dependencies, so that everything can be loaded in a single HTML object without a running Julia process. The defaults should already be chosen this way for e.g. Documenter, so this should mostly be used for e.g. `Pluto` offline export (which is currently not fully supported, but should be soon).

Here is an example of how to use this in Franklin:

```@example wglmakie
using WGLMakie
using Bonito, Markdown
Page() # for Franklin, you still need to configure
WGLMakie.activate!()
Makie.inline!(true) # Make sure to inline plots into Documenter output!
scatter(1:4, color=1:4)
```

As you can see, the output is completely static, because we don't have a running Julia server, as it would be the case with e.g. Pluto.
To make the plot interactive, we will need to write more parts of WGLMakie in JS, which is an ongoing effort.
As you can see, the interactivity already keeps working for 3D:

```@example wglmakie
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

There are a couple of ways to keep interacting with Plots in a static export.

## Record a statemap

Bonito allows to record a statemap for all widgets, that satisfy the following interface:

```julia
# must be true to be found inside the DOM
is_widget(x) = true
# Updating the widget isn't dependent on any other state (only thing supported right now)
is_independant(x) = true
# The values a widget can iterate
function value_range end
# updating the widget with a certain value (usually an observable)
function update_value!(x, value) end
```

Currently, only sliders overload the interface:

```@example wglmakie
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
    return Bonito.record_states(session, DOM.div(slider, fig))
end
```

## Execute Javascript directly

Bonito makes it easy to build whole HTML and JS applications.
You can for example directly register JavaScript function that get run on change.

```@example wglmakie
using Bonito

App() do session::Session
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

One can also interpolate plots into JS and update those via JS.
The problem is, that there isn't an amazing interface yet.
The returned object is directly a THREE object, with all plot attributes converted into Javascript types.
The good news is, all attributes should be in either `three_scene.material.uniforms`, or `three_scene.geometry.attributes`.
Going forward, we should create an API in WGLMakie, that makes it as easy as in Julia: `plot.attribute = value`.
But while this isn't in place, logging the the returned object makes it pretty easy to figure out what to do - btw, the JS console + logging is amazing and makes it very easy to play around with the object once logged.

```@example wglmakie
using Bonito: on_document_load
using WGLMakie

App() do session::Session
    s1 = Slider(1:100)
    slider_val = DOM.p(s1[]) # initialize with current value

    fig, ax, splot = scatter(1:4)

    # With on_document_load one can run JS after everything got loaded.
    # This is an alternative to `evaljs`, which we can't use here,
    # since it gets run asap, which means the plots won't be found yet.
    on_document_load(session, js"""
        // you get a promise for an array of plots, when interpolating into JS:
        $(splot).then(plots=>{
            // just one plot for atomics like scatter, but for recipes it can be multiple plots
            const scatter_plot = plots[0]
            // open the console with ctr+shift+i, to inspect the values
            // tip - you can right click on the log and store the actual variable as a global, and directly interact with it to change the plot.
            console.log(scatter_plot)
            console.log(scatter_plot.material.uniforms)
            console.log(scatter_plot.geometry.attributes)
        })
    """)

    # with the above, we can find out that the positions are stored in `offset`
    # (*sigh*, this is because threejs special cases `position` attributes so it can't be used)
    # Now, lets go and change them when using the slider :)
    onjs(session, s1.value, js"""function on_update(new_value) {
        $(splot).then(plots=>{
            const scatter_plot = plots[0]
            // change first point x + y value
            scatter_plot.geometry.attributes.pos.array[0] = (new_value/100) * 4
            scatter_plot.geometry.attributes.pos.array[1] = (new_value/100) * 4
            // this always needs to be set of geometry attributes after an update
            scatter_plot.geometry.attributes.pos.needsUpdate = true
        })
    }
    """)
    # and for got measures, add a slider to change the color:
    color_slider = Slider(LinRange(0, 1, 100))
    onjs(session, color_slider.value, js"""function on_update(hue) {
        $(splot).then(plots=>{
            const scatter_plot = plots[0]
            const color = new THREE.Color()
            color.setHSL(hue, 1.0, 0.5)
            scatter_plot.material.uniforms.color.value.x = color.r
            scatter_plot.material.uniforms.color.value.y = color.g
            scatter_plot.material.uniforms.color.value.z = color.b
        })
    }""")

    markersize = Slider(1:100)
    onjs(session, markersize.value, js"""function on_update(size) {
        $(splot).then(plots=>{
            const scatter_plot = plots[0]
            scatter_plot.material.uniforms.markersize.value.x = size
            scatter_plot.material.uniforms.markersize.value.y = size
        })
    }""")
    return DOM.div(s1, color_slider, markersize, fig)
end
```

This summarizes the current state of interactivity with WGLMakie inside static pages.


## Offline Tooltip

`Makie.DataInspector` works just fine with WGLMakie, but it requires a running Julia process to show and update the tooltip.

There is also a way to show a tooltip in Javascript directly, which needs to be inserted into the HTML dom.
This means, we actually need to use `Bonito.App` to return a `DOM` object:

```@example wglmakie
App() do session
    f, ax, pl = scatter(1:4, markersize=100, color=Float32[0.3, 0.4, 0.5, 0.6])
    custom_info = ["a", "b", "c", "d"]
    on_click_callback = js"""(plot, index) => {
        // the plot object is currently just the raw THREEJS mesh
        console.log(plot)
        // Which can be used to extract e.g. position or color:
        const {pos, color} = plot.geometry.attributes
        console.log(pos)
        console.log(color)
        const x = pos.array[index*2] // everything is a flat array in JS
        const y = pos.array[index*2+1]
        const c = Math.round(color.array[index] * 10) / 10 // rounding to a digit in JS
        const custom = $(custom_info)[index]
        // return either a string, or an HTMLNode:
        return "Point: <" + x + ", " + y + ">, value: " + c + " custom: " + custom
    }
    """

    # ToolTip(figurelike, js_callback; plots=plots_you_want_to_hover)
    tooltip = WGLMakie.ToolTip(f, on_click_callback; plots=pl)
    return DOM.div(f, tooltip)
end
```

# Pluto/IJulia

Note that the normal interactivity from Makie is preserved with WGLMakie in e.g. Pluto, as long as the Julia session is running.
Which brings us to setting up Pluto/IJulia sessions!
Locally, WGLMakie should just work out of the box for Pluto/IJulia, but if you're accessing the notebook from another PC, you must set something like:

```julia
begin
    using Bonito
    some_forwarded_port = 8080
    Page(listen_url="0.0.0.0", listen_port=some_forwarded_port)
end
```
Or also specify a proxy URL, if you have a more complex proxy setup.
For more advanced setups consult the `?Page` docs and `Bonito.configure_server!`.
In the [headless](@ref "Using WGLMakie") documentation, you can also read more about setting up the Bonito server and port forwarding.

## Styling

Bonito allows to load arbitrary css, and `DOM.xxx` wraps all existing HTML tags.
So any CSS file can be used, e.g. even libraries like [Tailwind](https://tailwindcss.com/) with `Asset`:

```julia
TailwindCSS = Bonito.Asset("/path/to/tailwind.min.css")
```

Bonito also offers the `Styles` type, which allows to define whole stylesheets and assign them to any DOM object.
That's how Bonito creates styleable components:

```julia
Rows(args...) = DOM.div(args..., style=Styles(
    "display" => "grid",
    "grid-template-rows" => "fr",
    "grid-template-columns" => "repeat($(length(args)), fr)",
))
```
This Style object will only be inserted one time into the DOM in one Session, and subsequent uses will just give the div the same class.

Note, that Bonito already defines something like the above `Rows`:

```@example wglmakie
using Colors
using Bonito

App() do session::Session
    hue_slider = Slider(0:360)
    color_swatch = DOM.div(class="h-6 w-6 p-2 m-2 rounded shadow")
    onjs(session, hue_slider.value, js"""function (hue){
        $(color_swatch).style.backgroundColor = "hsl(" + hue + ",60%,50%)"
    }""")
    return Row(hue_slider, color_swatch)
end
```

Bonito also offers a styleable Card component:

```@example wglmakie
using Markdown

App() do session::Session
    # We can now use this wherever we want:
    fig = Figure(size=(300, 300))
    contour(fig[1,1], rand(4,4))
    card = Card(Grid(
        Centered(DOM.h1("Hello"); style=Styles("grid-column" => "1 / 3")),
        StylableSlider(1:100; style=Styles("grid-column" => "1 / 3")),
        DOM.img(src="https://julialang.org/assets/infra/logo.svg"),
        fig; columns="1fr 1fr", justify_items="stretch"
    ))
    # Markdown creates a DOM as well, and you can interpolate
    # arbitrary jsrender'able elements in there:
    return DOM.div(card)
end
```

Hopefully, over time there will be helper libraries with lots of stylised elements like the above, to make flashy dashboards with Bonito + WGLMakie.

# Export

Documenter just renders the plots + Page as html,
so if you want to inline WGLMakie/Bonito objects into your own page,
one can just use something like this:

```julia
using WGLMakie, Bonito, FileIO
WGLMakie.activate!()

open("index.html", "w") do io
    println(io, """
    <html>
        <head>
        </head>
        <body>
    """)
    Page(exportable=true, offline=true)
    # Then, you can just inline plots or whatever you want :)
    # Of course it would make more sense to put this into a single app
    app = App() do
        C(x;kw...) = Card(x; height="fit-content", width="fit-content", kw...)
        figure = (; size=(300, 300))
        f1 = scatter(1:4; figure)
        f2 = mesh(load(assetpath("brain.stl")); figure)
        C(DOM.div(
            Bonito.StylableSlider(1:100),
            Row(C(f1), C(f2))
        ); padding="30px", margin="15px")
    end
    show(io, MIME"text/html"(), app)
    # or anything else from Bonito, or that can be displayed as html:
    println(io, """
        </body>
    </html>
    """)
end
```
