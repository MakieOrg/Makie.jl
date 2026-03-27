# =============================================================================
# draw_atomic for Makie.Image and Makie.Heatmap
# =============================================================================
# Creates a LavaRenderObject with a textured quad pipeline.
# Pipeline and texture are created once, updated in-place on data changes.

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
        pv = Mat4f(scene.camera.projectionview[])
        viewport = scene.viewport[]
        vw, vh = viewport.widths
        vo = viewport.origin

        function project_to_screen(dx, dy)
            p4 = pv * model * Vec4f(dx, dy, 0f0, 1f0)
            ndc = Vec2f(p4[1] / p4[4], p4[2] / p4[4])
            Point2f(vo[1] + (ndc[1] + 1f0) * 0.5f0 * vw,
                    vo[2] + (ndc[2] + 1f0) * 0.5f0 * vh)
        end

        p_bl = project_to_screen(x_min, y_min)
        p_tr = project_to_screen(x_max, y_max)

        # Convert image data to RGBA Float32
        rgba_data = if img_data isa AbstractMatrix{<:Colorant}
            RGBA{Float32}.(img_data)
        elseif img_data isa AbstractMatrix{<:Real}
            # Heatmap: apply colormap
            cmap_colors = to_value(plot.colormap)
            crange = to_value(plot.colorrange)
            _apply_colormap(img_data, cmap_colors, crange)
        else
            fill(RGBA{Float32}(1, 0, 1, 1), size(img_data))
        end

        # Reinterpret RGBA{Float32} → NTuple{4,Float32} for texture upload
        img_ntuple = collect(reinterpret(NTuple{4, Float32}, rgba_data))

        # Get root resolution for viewport
        root_w, root_h = size(screen.state.makie_scene)

        if !isnothing(last) && last.trace_renderobject isa LavaRenderObject
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
        robj = LavaRenderObject(pipeline;
            arg_names = (:screen_bl, :screen_tr, :res),
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
