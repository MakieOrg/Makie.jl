# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using JSServe: on_document_load
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
end # hide
println("~~~") # hide
show(stdout, MIME"text/html"(), __result) # hide
println("~~~") # hide
nothing # hide