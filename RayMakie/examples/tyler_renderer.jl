using Tyler, WGLMakie, RayMakie
using Tyler: ElevationProvider
using Hikari
using Makie
using AMDGPU
using Colors

"""
Interactive app that shows Tyler's 3D elevation map on the left (GLMakie preview)
and renders it via RayMakie on the right when the Render button is clicked.
"""
function tyler_renderer_app(;
        lat = 47.087441,
        lon = 13.377214,
        delta = 0.3,
        figsize = (1600, 800),
    )
    # Create the main figure with two panels
    fig = Figure(; size=figsize)

    # Left panel: GLMakie controls and preview
    left_panel = fig[1, 1] = GridLayout()

    # Control panel at top
    controls = left_panel[1, 1] = GridLayout()

    # Backend selection
    Label(controls[1, 1], "Backend:", halign=:right)
    backend_menu = Menu(controls[1, 2], options=["CPU", "GPU (ROCArray)"], default="CPU")

    # Integrator selection
    Label(controls[1, 3], "Integrator:", halign=:right)
    integrator_menu = Menu(controls[1, 4], options=["FastWavefront", "Whitted"], default="FastWavefront")

    # Samples
    Label(controls[2, 1], "Samples:", halign=:right)
    samples_slider = Slider(controls[2, 2], range=1:64, startvalue=8)
    samples_label = Label(controls[2, 3], @lift(string($(samples_slider.value))))

    # Max depth
    Label(controls[2, 4], "Max Depth:", halign=:right)
    depth_slider = Slider(controls[2, 5], range=1:10, startvalue=5)
    depth_label = Label(controls[2, 6], @lift(string($(depth_slider.value))))

    # Postprocessing controls
    Label(controls[3, 1], "Exposure:", halign=:right)
    exposure_slider = Slider(controls[3, 2], range=0.1:0.1:5.0, startvalue=1.0)
    exposure_label = Label(controls[3, 3], @lift(string(round($(exposure_slider.value), digits=1))))

    Label(controls[3, 4], "Tonemap:", halign=:right)
    tonemap_menu = Menu(controls[3, 5], options=["aces", "reinhard", "uncharted2", "filmic", "none"], default="aces")

    Label(controls[4, 1], "Gamma:", halign=:right)
    gamma_slider = Slider(controls[4, 2], range=1.0:0.1:3.0, startvalue=2.2)
    gamma_label = Label(controls[4, 3], @lift(string(round($(gamma_slider.value), digits=1))))

    # Render button
    render_btn = Button(controls[4, 4:5], label="Render", tellwidth=false)

    # Status label
    status_label = Label(controls[5, 1:5], "Ready", halign=:left)

    # Tyler 3D map in left panel
    ext = Rect2f(lon - delta/2, lat - delta/2, delta, delta)

    # Create LScene for Tyler map
    tyler_lscene = LScene(left_panel[2, 1], show_axis=false)
    tyler_map = Tyler.Map3D(ext; figure=fig, axis=tyler_lscene, provider=ElevationProvider())

    # Right panel: Rendered image
    right_panel = fig[1, 2] = GridLayout()
    Label(right_panel[1, 1], "Ray Traced Result", fontsize=16, tellwidth=false)

    # Create an axis for the rendered image
    render_ax = Axis(right_panel[2, 1], aspect=DataAspect())
    hidedecorations!(render_ax)

    # Placeholder image
    placeholder = zeros(RGB{Float32}, 100, 100)
    render_image = image!(render_ax, placeholder)

    # Set equal column widths
    colsize!(fig.layout, 1, Relative(0.5))
    colsize!(fig.layout, 2, Relative(0.5))

    # Render function
    function do_render()
        status_label.text = "Rendering..."

        try
            # Get the Tyler scene
            tyler_scene = tyler_lscene.scene

            # Get settings
            samples = samples_slider.value[]
            max_depth = depth_slider.value[]
            backend_str = backend_menu.selection[]
            integrator_str = integrator_menu.selection[]
            exposure = Float32(exposure_slider.value[])
            tonemap_sym = Symbol(tonemap_menu.selection[])
            gamma = Float32(gamma_slider.value[])

            if tonemap_sym == :none
                tonemap_sym = nothing
            end

            # Add SunSkyLight to Tyler scene for proper illumination
            # Tyler scenes only have ambient light by default
            status_label.text = "Setting up lights..."
            existing_lights = Makie.get_lights(tyler_scene)
            # Only add SunSkyLight if not already present
            if !any(l -> l isa SunSkyLight, existing_lights)
                sun_dir = Vec3f(0.5, 0.3, 1.0)  # Sun from upper right
                sun_sky = SunSkyLight(sun_dir; intensity=50.0, turbidity=2.5)
                Makie.push_light!(tyler_scene, sun_sky)
            end

            # Create integrator based on selection
            integrator = if integrator_str == "FastWavefront"
                Hikari.FastWavefront(samples=samples)
            else
                Hikari.Whitted(samples=samples, max_depth=max_depth)
            end

            # Select backend
            backend = backend_str == "CPU" ? Raycore.KA.CPU() : AMDGPU.ROCBackend()

            # Render using colorbuffer - handles scene conversion, rendering, and postprocessing
            status_label.text = "Rendering with $integrator_str ($samples samples)..."
            result = Makie.colorbuffer(tyler_scene;
                backend=RayMakie,
                integrator=integrator,
                array_type=backend,
                exposure=exposure,
                tonemap=tonemap_sym,
                gamma=gamma,
            )

            # Update the rendered image
            render_image[1] = result
            autolimits!(render_ax)
            status_label.text = "Done! ($(size(result, 1))×$(size(result, 2)))"
        catch e
            status_label.text = "Error: $(sprint(showerror, e))"
            @error "Render failed" exception=(e, catch_backtrace())
        end
    end

    # Connect render button
    on(render_btn.clicks) do _
        @async do_render()
    end

    # Return the figure - Tyler will handle display via its own mechanisms
    return fig, tyler_map
end

# Run the app
WGLMakie.activate!()  # Ensure WGLMakie is active for display
fig, tyler_map = tyler_renderer_app()
wait(tyler_map)  # Wait for Tyler data to load
fig
