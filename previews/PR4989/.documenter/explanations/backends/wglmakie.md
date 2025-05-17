
# WGLMakie {#WGLMakie}

[WGLMakie](https://github.com/MakieOrg/Makie.jl/tree/master/WGLMakie) is the web-based backend, which is mostly implemented in Julia right now. WGLMakie uses [Bonito](https://github.com/SimonDanisch/Bonito.jl) to generate the HTML and JavaScript for displaying the plots. On the JavaScript side, we use [ThreeJS](https://threejs.org/) and [WebGL](https://en.wikipedia.org/wiki/WebGL) to render the plots. Moving more of the implementation to JavaScript is currently the goal and will give us a better JavaScript API, and more interaction without a running Julia server.

::: warning Warning

WGLMakie can be considered experimental because the JavaScript API isn&#39;t stable yet and the notebook integration isn&#39;t perfect yet, but all plot types should work, and therefore all recipes, but there are certain caveats

:::

#### Browser Support {#Browser-Support}

##### IJulia {#IJulia}
- Bonito now uses the IJulia connection, and therefore can be used even with complex proxy setup without any additional setup
  
- reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that `Page()` is executed first.
  

#### JupyterHub / Jupyterlab / Binder {#JupyterHub-/-Jupyterlab-/-Binder}
- WGLMakie should mostly work with a websocket connection. Bonito tries to [infer the proxy setup](https://github.com/SimonDanisch/Bonito.jl/blob/master/src/server-defaults.jl) needed to connect to the julia process. On local jupyterlab instances, this should work without problem. On hosted instances one will likely need to have [`jupyter-server-proxy`](https://jupyter-server-proxy.readthedocs.io/en/latest/arbitrary-ports-hosts.html#with-jupyterhub) installed, and then execute something like `Page(; listen_port=9091, proxy_url="<jhub-instance>.com/user/<username>/proxy/9091")`.
  Also see:
  - [issue #2464](https://github.com/MakieOrg/Makie.jl/issues/2464)
    
  - [issue #2405](https://github.com/MakieOrg/Makie.jl/issues/2405)
    
  

#### Pluto {#Pluto}
- still uses Bonito&#39;s Websocket connection, so needs extra setup for remote servers.
  
- reload of the page isn&#39;t supported, if you reload, you need to re-execute all cells and make sure that `Page()` is executed first.
  
- static html export not fully working yet
  

#### JuliaHub {#JuliaHub}
- VSCode in the browser should work out of the box.
  
- Pluto in JuliaHub still has a [problem](https://github.com/SimonDanisch/Bonito.jl/issues/140) with the WebSocket connection. So, you will see a plot, but interaction doesn&#39;t work.
  

#### Browser Support {#Browser-Support-2}

Some browsers may have only WebGL 1.0, or need extra steps to enable WebGL, but in general, all modern browsers on [mobile and desktop should support WebGL 2.0](https://www.lambdatest.com/web-technologies/webgl2). Safari users may need to [enable](https://discussions.apple.com/thread/8655829) WebGL, though. If you end up stuck on WebGL 1.0, the main missing feature will be `volume` &amp; `contour(volume)`.

## Activation and screen config {#Activation-and-screen-config}

Activate the backend by calling `WGLMakie.activate!()` with the following options:
<details class='jldocstring custom-block' open>
<summary><a id='WGLMakie.activate!' href='#WGLMakie.activate!'><span class="jlbinding">WGLMakie.activate!</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
WGLMakie.activate!(; screen_config...)
```


Sets WGLMakie as the currently active backend and also allows to quickly set the `screen_config`. Note, that the `screen_config` can also be set permanently via `Makie.set_theme!(WGLMakie=(screen_config...,))`.

**Arguments one can pass via `screen_config`:**
- `framerate = 30`: Set framerate (frames per second) to a higher number for smoother animations, or to a lower to use less resources.
  
- `resize_to = nothing`: Resize the canvas to the parent element with `resize_to=:parent`, or to the body if `resize_to = :body`. The default `nothing`, will resize nothing.   A tuple is allowed too, with the same values just for width/height.
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/d2876406fadce67d5357789b0b71495e7971e5c1/WGLMakie/src/WGLMakie.jl#L50-L59" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Output {#Output}

You can use Bonito and WGLMakie in Pluto, IJulia, Webpages and Documenter to create interactive apps and dashboards, serve them on live webpages, or export them to static HTML.

This tutorial will run through the different modes and what kind of limitations to expect.

### Page {#Page}

`Page()` can be used to reset the Bonito state needed for multipage output like it&#39;s the case for `Documenter` or the various notebooks (IJulia/Pluto/etc). Previously, it was necessary to always insert and display the `Page` call in notebooks, but now the call to `Page()` is optional and doesn&#39;t need to be displayed. What it does is purely reset the state for a new multi-page output, which is usually the case for `Documenter`, which creates multiple pages in one Julia session, or you can use it to reset the state in notebooks, e.g. after a page reload. `Page(exportable=true, offline=true)` can be used to force inlining all data &amp; js dependencies, so that everything can be loaded in a single HTML object without a running Julia process. The defaults should already be chosen this way for e.g. Documenter, so this should mostly be used for e.g. `Pluto` offline export (which is currently not fully supported, but should be soon).

Here is an example of how to use this in Franklin:

```julia
using WGLMakie
using Bonito, Markdown
Page() # for Franklin, you still need to configure
WGLMakie.activate!()
Makie.inline!(true) # Make sure to inline plots into Documenter output!
scatter(1:4, color=1:4)
```

<div v-html="`&lt;div&gt;&#10;  &lt;div class=&quot;bonito-fragment&quot; id=&quot;5e0d83e5-462a-4c28-9548-6db133bcd178&quot; data-jscall-id=&quot;root&quot;&gt;&#10;    &lt;div&gt;&#10;      &lt;script src=&quot;bonito/js/Bonito.bundled15432232505923397289.js&quot; type=&quot;module&quot;&gt;&lt;/script&gt;&#10;      &lt;style&gt;&lt;/style&gt;&#10;    &lt;/div&gt;&#10;    &lt;div&gt;&#10;      &lt;script type=&quot;module&quot;&gt;Bonito.lock_loading(() =&gt; Bonito.init_session(&#39;5e0d83e5-462a-4c28-9548-6db133bcd178&#39;, null, &#39;root&#39;, false))&lt;/script&gt;&#10;      &lt;span&gt;&lt;/span&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;  &lt;div class=&quot;bonito-fragment&quot; id=&quot;55fa0184-ced1-40d6-ade7-adccc0a3e5ab&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;    &lt;div&gt;&#10;      &lt;style&gt;&lt;/style&gt;&#10;    &lt;/div&gt;&#10;    &lt;div&gt;&#10;      &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/039982bafb8b574cf51180e7ccdcdb866769ed0f-14723098364706152997.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;55fa0184-ced1-40d6-ade7-adccc0a3e5ab&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;      &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;1&quot;&gt;&#10;        &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-jscall-id=&quot;2&quot; data-lm-suppress-shortcuts=&quot;true&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;      &lt;/div&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

As you can see, the output is completely static, because we don&#39;t have a running Julia server, as it would be the case with e.g. Pluto. To make the plot interactive, we will need to write more parts of WGLMakie in JS, which is an ongoing effort. As you can see, the interactivity already keeps working for 3D:

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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;9bd48dba-6b4b-49ec-914c-058593e2283b&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/bacbfb71b91ae5e68b3dcfaa9063a2de996ff4be-5017037494274775761.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;9bd48dba-6b4b-49ec-914c-058593e2283b&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;3&quot;&gt;&#10;      &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-jscall-id=&quot;4&quot; data-lm-suppress-shortcuts=&quot;true&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

There are a couple of ways to keep interacting with Plots in a static export.

## Record a statemap {#Record-a-statemap}

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
    return Bonito.record_states(session, DOM.div(slider, fig))
end
```

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;de72b79a-779f-48a3-8284-6e246d22ead4&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/682684c008e609dd80843ac88a5eafc33dd4b991-9263726605999005481.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;de72b79a-779f-48a3-8284-6e246d22ead4&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div data-jscall-id=&quot;5&quot;&gt;&#10;      &lt;div data-jscall-id=&quot;6&quot;&gt;z-index: &#10;        &lt;input step=&quot;1&quot; max=&quot;10&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;7&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;        &lt;span data-jscall-id=&quot;8&quot;&gt;1&lt;/span&gt;&#10;      &lt;/div&gt;&#10;      &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;9&quot;&gt;&#10;        &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-jscall-id=&quot;10&quot; data-lm-suppress-shortcuts=&quot;true&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;      &lt;/div&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

## Execute Javascript directly {#Execute-Javascript-directly}

Bonito makes it easy to build whole HTML and JS applications. You can for example directly register JavaScript function that get run on change.

```julia
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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;6d9550b7-a470-4aae-a34d-db0c0d235785&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/b8ea3dd3af9e0ebf148b6bb200cb77f48fd85905-6838252149935344987.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;6d9550b7-a470-4aae-a34d-db0c0d235785&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div data-jscall-id=&quot;12&quot;&gt;slider 1: &#10;      &lt;input step=&quot;1&quot; max=&quot;100&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;13&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;      &lt;p data-jscall-id=&quot;11&quot;&gt;1&lt;/p&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

One can also interpolate plots into JS and update those via JS. The problem is, that there isn&#39;t an amazing interface yet. The returned object is directly a THREE object, with all plot attributes converted into Javascript types. The good news is, all attributes should be in either `three_scene.material.uniforms`, or `three_scene.geometry.attributes`. Going forward, we should create an API in WGLMakie, that makes it as easy as in Julia: `plot.attribute = value`. But while this isn&#39;t in place, logging the the returned object makes it pretty easy to figure out what to do - btw, the JS console + logging is amazing and makes it very easy to play around with the object once logged.

```julia
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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;30a091ce-c409-4bf8-9769-bff593fbbc6d&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/48df4f635315a304297137e3af569ace9f9e7837-6158018536001056027.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;30a091ce-c409-4bf8-9769-bff593fbbc6d&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div data-jscall-id=&quot;14&quot;&gt;&#10;      &lt;input step=&quot;1&quot; max=&quot;100&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;15&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;      &lt;input step=&quot;1&quot; max=&quot;100&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;16&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;      &lt;input step=&quot;1&quot; max=&quot;100&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;17&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;      &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;18&quot;&gt;&#10;        &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-lm-suppress-shortcuts=&quot;true&quot; data-jscall-id=&quot;19&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;      &lt;/div&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

This summarizes the current state of interactivity with WGLMakie inside static pages.

## Offline Tooltip {#Offline-Tooltip}

`Makie.DataInspector` works just fine with WGLMakie, but it requires a running Julia process to show and update the tooltip.

There is also a way to show a tooltip in Javascript directly, which needs to be inserted into the HTML dom. This means, we actually need to use `Bonito.App` to return a `DOM` object:

```julia
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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;690cc76b-c5dc-4fd9-9011-59c9b825773d&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;&lt;/style&gt;&#10;    &lt;link href=&quot;bonito/css/popup12105019685282523530.css&quot; rel=&quot;stylesheet&quot; type=&quot;text/css&quot; /&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/2977d0d637fc47502538441337586a9b71d65c3b-8436860718475649272.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;690cc76b-c5dc-4fd9-9011-59c9b825773d&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div data-jscall-id=&quot;20&quot;&gt;&#10;      &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;21&quot;&gt;&#10;        &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-lm-suppress-shortcuts=&quot;true&quot; data-jscall-id=&quot;22&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;      &lt;/div&gt;&#10;      &lt;span&gt;&#10;        &lt;div class=&quot;popup&quot; data-jscall-id=&quot;23&quot;&gt;&lt;/div&gt;&#10;      &lt;/span&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

# Pluto/IJulia {#Pluto/IJulia}

Note that the normal interactivity from Makie is preserved with WGLMakie in e.g. Pluto, as long as the Julia session is running. Which brings us to setting up Pluto/IJulia sessions! Locally, WGLMakie should just work out of the box for Pluto/IJulia, but if you&#39;re accessing the notebook from another PC, you must set something like:

```julia
begin
    using Bonito
    some_forwarded_port = 8080
    Page(listen_url="0.0.0.0", listen_port=some_forwarded_port)
end
```


Or also specify a proxy URL, if you have a more complex proxy setup. For more advanced setups consult the `?Page` docs and `Bonito.configure_server!`. In the [headless](/explanations/headless#Using-WGLMakie) documentation, you can also read more about setting up the Bonito server and port forwarding.

## Styling {#Styling}

Bonito allows to load arbitrary css, and `DOM.xxx` wraps all existing HTML tags. So any CSS file can be used, e.g. even libraries like [Tailwind](https://tailwindcss.com/) with `Asset`:

```julia
TailwindCSS = Bonito.Asset("/path/to/tailwind.min.css")
```


Bonito also offers the `Styles` type, which allows to define whole stylesheets and assign them to any DOM object. That&#39;s how Bonito creates styleable components:

```julia
Rows(args...) = DOM.div(args..., style=Styles(
    "display" => "grid",
    "grid-template-rows" => "fr",
    "grid-template-columns" => "repeat($(length(args)), fr)",
))
```


This Style object will only be inserted one time into the DOM in one Session, and subsequent uses will just give the div the same class.

Note, that Bonito already defines something like the above `Rows`:

```julia
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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;4bbe509c-2355-43e7-aaf0-5f87c80b2086&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;.style_2 {&#10;  justify-items: legacy;&#10;  align-items: legacy;&#10;  height: 100%;&#10;  display: grid;&#10;  align-content: normal;&#10;  grid-gap: 10px;&#10;  grid-template-rows: 1fr;&#10;  justify-content: normal;&#10;  grid-template-columns: repeat(2, 1fr);&#10;  width: 100%;&#10;  grid-template-areas: none;&#10;}&#10;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/296c36624a7a5532f6d7ffc19d310014ee18b319-12592370105008151581.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;4bbe509c-2355-43e7-aaf0-5f87c80b2086&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div class=&quot; style_2&quot; style=&quot;&quot; data-jscall-id=&quot;25&quot;&gt;&#10;      &lt;input step=&quot;1&quot; max=&quot;361&quot; min=&quot;1&quot; style=&quot;styles&quot; data-jscall-id=&quot;26&quot; value=&quot;1&quot; oninput=&quot;&quot; type=&quot;range&quot; /&gt;&#10;      &lt;div class=&quot;h-6 w-6 p-2 m-2 rounded shadow&quot; data-jscall-id=&quot;24&quot;&gt;&lt;/div&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

Bonito also offers a styleable Card component:

```julia
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

<div v-html="`&lt;div class=&quot;bonito-fragment&quot; id=&quot;4fd4e3e9-1780-4148-a2be-997785bc9d19&quot; data-jscall-id=&quot;subsession-application-dom&quot;&gt;&#10;  &lt;div&gt;&#10;    &lt;style&gt;.style_3 {&#10;  justify-items: center;&#10;  align-items: center;&#10;  height: 100%;&#10;  display: grid;&#10;  align-content: center;&#10;  grid-gap: 10px;&#10;  grid-template-rows: none;&#10;  justify-content: center;&#10;  grid-template-columns: 1fr;&#10;  width: 100%;&#10;  grid-column: 1 / 3;&#10;  grid-template-areas: none;&#10;}&#10;.style_4 {&#10;  justify-items: stretch;&#10;  align-items: legacy;&#10;  height: 100%;&#10;  display: grid;&#10;  align-content: normal;&#10;  grid-gap: 10px;&#10;  grid-template-rows: none;&#10;  justify-content: normal;&#10;  grid-template-columns: 1fr 1fr;&#10;  width: 100%;&#10;  grid-template-areas: none;&#10;}&#10;.style_5 {&#10;  align-items: center;&#10;  grid-column: 1 / 3;&#10;  display: grid;&#10;  background-color: transparent;&#10;  grid-template-columns: 1fr;&#10;  padding-right: 9.5px;&#10;  position: relative;&#10;  margin: 5px;&#10;  grid-template-rows: 15px;&#10;  padding-left: 9.5px;&#10;}&#10;.style_6 {&#10;  left: -7.5px;&#10;  height: 15px;&#10;  border: 1px solid #ccc;&#10;  background-color: #fff;&#10;  position: absolute;&#10;  width: 15px;&#10;  border-radius: 50%;&#10;  cursor: pointer;&#10;}&#10;.style_7 {&#10;  height: 9.5px;&#10;  border: 1px solid #ccc;&#10;  background-color: #ddd;&#10;  position: absolute;&#10;  width: 0px;&#10;  border-radius: 3px;&#10;}&#10;.style_8 {&#10;  height: auto;&#10;  padding: 12px;&#10;  background-color: rgba(255.0, 255.0, 255.0, 0.2);&#10;  box-shadow: 0 4px 8px rgba(0.0, 0.0, 51.0, 0.2);&#10;  width: auto;&#10;  border-radius: 10px;&#10;  margin: 2px;&#10;}&#10;.style_9 {&#10;  height: 7.5px;&#10;  border: 1px solid #ccc;&#10;  background-color: #eee;&#10;  position: absolute;&#10;  width: 100%;&#10;  border-radius: 3px;&#10;}&#10;&lt;/style&gt;&#10;  &lt;/div&gt;&#10;  &lt;div&gt;&#10;    &lt;script type=&quot;module&quot;&gt;    Bonito.lock_loading(() =&gt; {&#10;        return Bonito.fetch_binary(&#39;bonito/bin/38d02e6a2465526b7b4e77eb1faa02e873d29eeb-4444691587058128896.bin&#39;).then(msgs=&gt; Bonito.init_session(&#39;4fd4e3e9-1780-4148-a2be-997785bc9d19&#39;, msgs, &#39;sub&#39;, false));&#10;    })&#10;&lt;/script&gt;&#10;    &lt;div data-jscall-id=&quot;27&quot;&gt;&#10;      &lt;div class=&quot; style_8&quot; style=&quot;&quot; data-jscall-id=&quot;28&quot;&gt;&#10;        &lt;div class=&quot; style_4&quot; style=&quot;&quot; data-jscall-id=&quot;29&quot;&gt;&#10;          &lt;div class=&quot; style_3&quot; style=&quot;&quot; data-jscall-id=&quot;30&quot;&gt;&#10;            &lt;h1 data-jscall-id=&quot;31&quot;&gt;Hello&lt;/h1&gt;&#10;          &lt;/div&gt;&#10;          &lt;div class=&quot; style_5&quot; style=&quot;&quot; data-jscall-id=&quot;32&quot;&gt;&#10;            &lt;div class=&quot; style_9&quot; style=&quot;&quot; data-jscall-id=&quot;33&quot;&gt;&lt;/div&gt;&#10;            &lt;div class=&quot; style_7&quot; style=&quot;&quot; data-jscall-id=&quot;34&quot;&gt;&lt;/div&gt;&#10;            &lt;div class=&quot; style_6&quot; style=&quot;&quot; data-jscall-id=&quot;35&quot;&gt;&lt;/div&gt;&#10;          &lt;/div&gt;&#10;          &lt;img data-jscall-id=&quot;36&quot; src=&quot;https://julialang.org/assets/infra/logo.svg&quot; /&gt;&#10;          &lt;div style=&quot;width: 100%; height: 100%&quot; data-jscall-id=&quot;37&quot;&gt;&#10;            &lt;canvas data-jp-suppress-context-menu style=&quot;display: block&quot; data-lm-suppress-shortcuts=&quot;true&quot; data-jscall-id=&quot;38&quot; tabindex=&quot;0&quot;&gt;&lt;/canvas&gt;&#10;          &lt;/div&gt;&#10;        &lt;/div&gt;&#10;      &lt;/div&gt;&#10;    &lt;/div&gt;&#10;  &lt;/div&gt;&#10;&lt;/div&gt;`"></div>

Hopefully, over time there will be helper libraries with lots of stylised elements like the above, to make flashy dashboards with Bonito + WGLMakie.

# Export {#Export}

Documenter just renders the plots + Page as html, so if you want to inline WGLMakie/Bonito objects into your own page, one can just use something like this:

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

