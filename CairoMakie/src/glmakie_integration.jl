# Upstreamable code

# TODO: make this function more efficient!
function alpha_colorbuffer(scene)
    GLMakie.activate!()
    display(scene)
    bg = scene.backgroundcolor[]
    scene.backgroundcolor[] = RGBAf(0, 0, 0, 1)
    b1 = copy(Makie.colorbuffer(scene))
    scene.backgroundcolor[] = RGBAf(1, 1, 1, 1)
    b2 = Makie.colorbuffer(scene)
    CairoMakie.activate!()
    scene.backgroundcolor[] = bg
    return map(infer_alphacolor, b1, b2)
end


function infer_alphacolor(rgb1, rgb2)
    rgb1 == rgb2 && return RGBAf(rgb1.r, rgb1.g, rgb1.b, 1)
    c1 = Float64.((rgb1.r, rgb1.g, rgb1.b))
    c2 = Float64.((rgb2.r, rgb2.g, rgb2.b))
    alpha = @. 1 - (c1 - c2) * -1 # ( / (0 - 1))
    meanalpha = clamp(sum(alpha) / 3, 0, 1)
    meanalpha == 0 && return RGBAf(0, 0, 0, 0)
    c = @. clamp((c1 / meanalpha), 0, 1)
    return RGBAf(c..., meanalpha)
end

function create_render_scene(plot::Combined; scale::Real = 1)
    scene = Makie.parent_scene(plot)
    w, h = Int.(scene.px_area[].widths)

    # We create a dummy scene to render to, which inherits its parent's
    # transformation and camera

    render_scene = Makie.Scene(
        camera = Makie.camera(scene),
        lights = scene.lights,
        ssao = scene.ssao,
        show_axis = false,
        backgroundcolor = :transparent
    )

    # continually keep the pixel area updated
    on(pixelarea(scene); update = true) do px_area
        Makie.resize!(render_scene, (px_area.widths .* scale)...)
    end

    # link the transofrmation attributes
    Makie.Observables.connect!(render_scene.transformation.transform_func, scene.transformation.transform_func)
    Makie.Observables.connect!(render_scene.transformation.rotation      , scene.transformation.rotation)
    Makie.Observables.connect!(render_scene.transformation.scale         , scene.transformation.scale)
    Makie.Observables.connect!(render_scene.transformation.translation   , scene.transformation.translation)
    Makie.Observables.connect!(render_scene.transformation.model         , scene.transformation.model)

    # push only the relevant plot to the scene
    push!(render_scene, plot)

    return render_scene

end
function plot2img(plot::Combined; scale::Real = 1, use_backgroundcolor = false)
    parent = Makie.parent_scene(plot)
    render_scene = if haskey(parent.theme, :_render_scenes) && haskey(parent.theme._render_scenes.val, plot)
        parent.theme._render_scenes.val[plot]
    else # we have to create a render scene
        println("Rerendering")
        scene = create_render_scene(plot; scale = scale)

        # set up cache
        rs_dict = get!(parent.theme.attributes, :_render_scenes, Dict{Union{Makie.AbstractPlot, Makie.Combined}, Makie.Scene}())
        rs_dict.val[plot] = scene

        scene
    end


    img = if use_backgroundcolor
        Makie.colorbuffer(render_scene)
    else # render with transparency, using the alpha-colorbuffer hack
        alpha_colorbuffer(render_scene)
    end

    return img
end

# Utility function to remove rendercaches
function purge_render_cache!(sc::Scene)
    haskey(scene.attributes, :_render_scenes) && delete!(scene.attributes, :_render_scenes)
    purge_render_cache!.(scene.children)
end
purge_render_cache!(fig::Figure) = purge_render_cache!(fig.scene)

# Rendering pipeline

# This goes as follows:
# The first time a plot is encountered which has to be rasterized,
# we create the rasterization scene, and connect it to the original Scene's
# attributes.
# Then, we retrieve this scene from `plot._render_scene`, an attribute of the plot
# which we set in the previous step to contain the scene.
# This retrieval


function CairoMakie.draw_atomic(scene::Scene, screen::CairoMakie.CairoScreen, primitive::Volume, scale::Real = 10)

    w, h = Int.(scene.px_area[].widths)

    img = plot2img(primitive; scale = scale, use_backgroundcolor = false)
    Makie.save("hi.png", img) # cache for debugging

    surf = CairoMakie.Cairo.CairoARGBSurface(CairoMakie.to_uint32_color.(img))

    CairoMakie.Cairo.rectangle(screen.context, 0, 0, w, h)
    CairoMakie.Cairo.save(screen.context)
    CairoMakie.Cairo.scale(screen.context, w / surf.width, h / surf.height)
    CairoMakie.Cairo.set_source_surface(screen.context, surf, 0, 0)
    p = CairoMakie.Cairo.get_source(screen.context)
    CairoMakie.Cairo.pattern_set_extend(p, CairoMakie.Cairo.EXTEND_PAD) # avoid blurry edges
    CairoMakie.Cairo.pattern_set_filter(p, CairoMakie.Cairo.FILTER_NEAREST)
    CairoMakie.Cairo.fill(screen.context)
    CairoMakie.Cairo.restore(screen.context)

    return

end
