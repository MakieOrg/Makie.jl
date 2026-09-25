# =============================================================================
# draw_atomic for Makie.Image and Makie.Heatmap
# =============================================================================
# Creates a RenderObject with a textured quad pipeline.
# Pipeline and texture are created once, updated in-place on data changes.

"""
    texeldata(image) -> Matrix{NTuple{4,UInt8}} or Matrix{NTuple{4,Float32}}

`image` as the texel tuples a texture is uploaded from, **in the precision the
image already has**.

An 8-bit source becomes `R8G8B8A8_UNORM` and a floating-point one
`R32G32B32A32_SFLOAT`. Both sample to a float in the shader — a UNORM texture is
normalised by the sampler, in hardware — so nothing downstream can tell the
difference, and neither can the picture: the 8-bit path is exact for an 8-bit
source rather than approximate.

Everything used to go to `RGBA{Float32}`. MEASURED on one 1920x1080 video frame:
`RGBA{Float32}.(img)` 30.0 ms and 31.6 MB, then
`collect(reinterpret(NTuple{4,Float32}, …))` another 16.0 ms and 31.6 MB — 46 ms
and 63 MB of host work per frame, to turn 5.9 MB of `RGB{N0f8}` into 31.6 MB to
upload. 46 ms a frame is a 21.7 fps ceiling, and the video editor's preview
measured 18.8.

The `reinterpret` copy was pure waste in both cases: an `RGBA{T}` matrix is
already four `T`s per texel, laid out exactly as the tuple. Broadcasting the
conversion straight to the tuple does it once.
"""
texeldata(img::AbstractMatrix{<:Colorant{N0f8}}) = rgba8texel.(img)
texeldata(img::AbstractMatrix{<:Colorant}) = rgba32texel.(img)

@inline function rgba8texel(c)
    x = RGBA{N0f8}(c)
    return (reinterpret(UInt8, red(x)), reinterpret(UInt8, green(x)),
            reinterpret(UInt8, blue(x)), reinterpret(UInt8, alpha(x)))
end

@inline function rgba32texel(c)
    x = RGBA{Float32}(c)
    return (red(x), green(x), blue(x), alpha(x))
end

function draw_atomic(screen::Screen, scene::Scene, plot::Union{Makie.Image, Makie.Heatmap})
    attr = plot.attributes

    # model_f32c may not exist for Heatmap — use identity if missing
    deps = haskey(attr, :model_f32c) ? [:x, :y, :image, :model_f32c] : [:x, :y, :image]
    register_computation!(attr, deps, [:trace_renderobject]) do args, changed, last
        x = to_value(args.x)
        y = to_value(args.y)
        img_data = to_value(args.image)
        model = hasproperty(args, :model_f32c) ? Mat4f(args.model_f32c) : (haskey(plot, :model_f32c) ? Mat4f(to_value(plot.model_f32c)) : Mat4f(I))

        # Get image bounds in data space
        x_min, x_max = Float32(minimum(x)), Float32(maximum(x))
        y_min, y_max = Float32(minimum(y)), Float32(maximum(y))

        # Project corners through camera to screen pixel coords
        # Both from the plot's OWN scene — see `plot_clip_matrix`. The matrix and
        # the viewport describe one mapping and have to come from one place.
        pv = plot_clip_matrix(plot)
        viewport = Makie.parent_scene(plot).viewport[]
        vw, vh = viewport.widths

        # The scene's OWN pixels, with no viewport origin added: the draw is
        # recorded under this scene's viewport, so the stage's `screen_to_ndc` maps
        # `[0, vw] x [0, vh]` onto exactly that rect. Adding the origin and then
        # dividing by the ROOT resolution — which is what this did, and what `res`
        # below still had to be for it — described the quad in window coordinates
        # and had them re-mapped into the axis a second time: an `image!` or a
        # `heatmap!` came out shrunk and pushed towards one corner of its own axis.
        # `lines` and `scatter` have always worked in the scene's own space.
        function project_to_screen(dx, dy)
            p4 = pv * model * Vec4f(dx, dy, 0f0, 1f0)
            ndc = Vec2f(p4[1] / p4[4], p4[2] / p4[4])
            # Y-DOWN, which is the space the overlay draws in — `screen_to_ndc`
            # in the shader and `collect_overlay_robjs`' `root_h - vp.origin[2]`
            # both assume it. NDC y is +1 at the TOP, so `(ndc+1)/2` is y-UP and
            # placed the quad mirrored about the viewport's centre: an image at
            # data y 0..16 of a 0..50 axis drew at 34..50. Every other plot
            # projects in the shader, where the viewport transform does this, so
            # this is the only place that has to say it.
            Point2f((ndc[1] + 1f0) * 0.5f0 * vw, (1f0 - ndc[2]) * 0.5f0 * vh)
        end

        p_bl = project_to_screen(x_min, y_min)
        p_tr = project_to_screen(x_max, y_max)

        # The texel tuple the texture is uploaded from, in the SOURCE's precision
        # — see `texeldata`. Straight to the tuple: this used to build an
        # `RGBA{Float32}` matrix and then `collect(reinterpret(...))` it, which is
        # a second full copy of a buffer that is already bit-for-bit what the
        # upload wants.
        img_ntuple = if img_data isa AbstractMatrix{<:Colorant}
            texeldata(img_data)
        elseif img_data isa AbstractMatrix{<:Real}
            # Heatmap: apply colormap. Computed in float, so it stays float.
            cmap_colors = to_value(plot.colormap)
            crange = to_value(plot.colorrange)
            texeldata(_apply_colormap(img_data, cmap_colors, crange))
        else
            fill((1f0, 0f0, 1f0, 1f0), size(img_data))
        end

        # The scene's own size, to match the pixels `project_to_screen` produced.
        root_w, root_h = round(Int, vw), round(Int, vh)

        if !isnothing(last) && last.trace_renderobject isa RenderObject
            # UPDATE existing render object
            robj = last.trace_renderobject
            robj.uniforms[:screen_bl] = Vec2f(p_bl)
            robj.uniforms[:screen_tr] = Vec2f(p_tr)
            robj.uniforms[:res] = Vec2f(Float32(root_w), Float32(root_h))
            update_texture!(robj, img_ntuple; filter=:linear, wrap=:clamp)
            robj.visible = true
            return (robj,)
        end

        # CREATE new render object
        pipeline = get_image_pipeline!(screen)
        robj = RenderObject(pipeline;
            backend = screen.config.device,
            arg_names = (:screen_bl, :screen_tr, :res, :fxaa),
            fxaa = plot_fxaa(plot),
            uniforms = Dict{Symbol, Any}(
                :screen_bl => Vec2f(p_bl),
                :screen_tr => Vec2f(p_tr),
                :res => Vec2f(Float32(root_w), Float32(root_h)),
            ),
            vertex_count = 6,
            instances = 1,
        )
        update_texture!(robj, img_ntuple; filter=:linear, wrap=:clamp)
        return (robj,)
    end
end

function _apply_colormap(data::AbstractMatrix{<:Real}, cmap, crange)
    cr = crange isa Makie.Automatic ? (Float32(minimum(data)), Float32(maximum(data))) :
                                       (Float32(crange[1]), Float32(crange[2]))
    cmin, cmax = cr
    cmap_rgba = RGBA{Float32}.(Makie.to_colormap(cmap))
    n = length(cmap_rgba)
    return map(data) do v
        fv = Float32(v)
        t = cmax > cmin ? clamp((fv - cmin) / (cmax - cmin), 0f0, 1f0) : 0.5f0
        idx = clamp(t * (n - 1) + 1, 1, n)
        i0 = floor(Int, idx)
        i1 = min(i0 + 1, n)
        f = idx - i0
        c0 = cmap_rgba[i0]; c1 = cmap_rgba[i1]
        RGBA{Float32}(c0.r*(1-f)+c1.r*f, c0.g*(1-f)+c1.g*f, c0.b*(1-f)+c1.b*f, c0.alpha*(1-f)+c1.alpha*f)
    end
end
