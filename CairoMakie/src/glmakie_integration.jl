function alpha_colorbuffer(scene)
    GLMakie.activate!()
    display(scene)
    bg = scene.backgroundcolor[]
    scene.backgroundcolor[] = RGBAf(0, 0, 0, 1)
    b1 = copy(Makie.colorbuffer(scene))
    FileIO.save("hi-white.png", b1)
    scene.backgroundcolor[] = RGBAf(1, 1, 1, 1)
    b2 = Makie.colorbuffer(scene)
    FileIO.save("hi-black.png", b2)
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

function plot2img(plot::Combined, scale::Real = 1; use_backgroundcolor = false)
    scene = Makie.parent_scene(plot)
    w, h = Int.(scene.px_area[].widths)

    # We create a dummy scene to render to, which inherits its parent's
    # transformation and camera

    render_scene = Makie.Scene(camera = Makie.camera(scene), lights = scene.lights, ssao = scene.ssao, show_axis = false, backgroundcolor = :transparent,)
    Makie.resize!(render_scene, (pixelarea(scene)[].widths .* scale)...)
    # copy over the transofrmation and camera attributes
    render_scene.transformation.transform_func[] = scene.transformation.transform_func[]
    render_scene.transformation.rotation[]       = scene.transformation.rotation[]
    render_scene.transformation.scale[]          = scene.transformation.scale[]
    render_scene.transformation.translation[]    = scene.transformation.translation[]

    # push only the relevant plot to the scene
    push!(render_scene, plot)

    img = if use_backgroundcolor
        Makie.colorbuffer(render_scene)
    else # render with transparency, using the alpha-colorbuffer hack
        alpha_colorbuffer(render_scene)
    end

    return img
end

function CairoMakie.draw_atomic(scene::Scene, screen::CairoMakie.CairoScreen, primitive::Volume, scale::Real = 10)

    w, h = Int.(scene.px_area[].widths)

    img = plot2img(primitive, scale; use_backgroundcolor = false)
    Makie.save("hi.png", img) # cache for debugging

    surf = Cairo.CairoARGBSurface(CairoMakie.to_uint32_color.(img))

    Cairo.rectangle(screen.context, 0, 0, w, h)
    Cairo.save(screen.context)
    Cairo.scale(screen.context, w / surf.width, h / surf.height)
    Cairo.set_source_surface(screen.context, surf, 0, 0)
    p = Cairo.get_source(screen.context)
    Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD) # avoid blurry edges
    Cairo.pattern_set_filter(p, Cairo.FILTER_NEAREST)
    Cairo.fill(screen.context)
    Cairo.restore(screen.context)

    return

end
