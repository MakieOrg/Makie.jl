"""
    tooltip(position, string)
    tooltip(x, y, string)

Creates a tooltip pointing at `position` displaying the given `string`

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `space::Symbol = :data` sets the transformation space for positions of markers. See `Makie.spaces()` for possible inputs.
    
### Tooltip specific

- `offset = 10` sets the offset between the given `position` and the tip of the triangle pointing at that position.
- `placement = :above` sets where the tooltipü should be placed relative to `position`. Can be `:above`, `:below`, `:left`, `:right`.
- `backgroundcolor = :white` sets the background color of the tooltip.
- `triangle_size = 10` sets the size of the triangle pointing at `position`.
- `outline_color = :black` sets the color of the tooltip outline.
- `outline_linewidth = 2f0` sets the linewidth of the tooltip outline.
- `outline_linestyle = nothing` sets the linestyle of the tooltip outline.

- `textpadding = (4, 4, 4, 4)` sets the padding around text in the tooltip. This is given as `(left, right, bottom top)` offsets.
- `textcolor = theme(scene, :textcolor)` sets the text color.
- `textsize = 16` sets the text size.
- `font = theme(scene, :font)` sets the font.
- `strokewidth = 0`: Gives text an outline if set to a positive value.
- `strokecolor = :white` sets the text outline color.
- `justification = :left` sets whether text is aligned to the `:left`, `:center` or `:right` within its bounding box.
"""
@recipe(Tooltip, position, str) do scene
    Attributes(;
        # General    
        offset = 10,
        placement = :above,
        xautolimits = false, 
        yautolimits = false, 
        zautolimits = false,
        overdraw = false,
        depth_shift = 0f0,
        transparency = false,
        visible = true,
        inspectable = false,

        # Text
        textpadding = (4, 4, 4, 4), # LRBT
        textcolor = theme(scene, :textcolor),
        textsize = 16,
        font = theme(scene, :font),
        strokewidth = 0,
        strokecolor = :white,
        justification = :left,

        # Background
        backgroundcolor = :white,
        triangle_size = 10,
        
        # Outline
        outline_color = :black,
        outline_linewidth = 2f0,
        outline_linestyle = nothing,
    )
end

convert_arguments(::Type{<: Tooltip}, x, y, str) = (Point2f(x, y), str)


function plot!(p::Tooltip)
    scene = parent_scene(p)
    bbox = Observable(Rect2f(0,0,1,1))
    textpadding = map(p.textpadding) do pad
        if pad isa Real
            return (pad, pad, pad, pad)
        elseif length(pad) == 4
            return pad
        else
            @error "Failed to parse $pad as (left, right, bottom, top). Using defaults"
            return (4, 4, 2, 2)
        end
    end

    # Text background mesh

    mesh!(
        p, bbox, shading = false, space = :pixel,
        color = p.backgroundcolor, fxaa = false,
        transparency = p.transparency, visible = p.visible, 
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable
    )

    # Triangle mesh

    triangle = GeometryBasics.Mesh(
        Point2f[(-0.5, 0), (0.5, 0), (0, -1)],
        GLTriangleFace[(1,2,3)]
    )

    mp = mesh!(
        p, triangle, shading = false, space = :pixel,
        color = p.backgroundcolor, 
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable
    )
    onany(bbox, p.triangle_size, p.placement) do bb, s, placement
        o = origin(bb)
        w = widths(bb)
        scale!(mp, s, s, s)
        
        if placement == :left 
            translate!(mp, Vec3f(o[1] + w[1], o[2] + 0.5w[2], 0))
            rotate!(mp, qrotation(Vec3f(0,0,1), 0.5pi))
        elseif placement == :right
            translate!(mp, Vec3f(o[1], o[2] + 0.5w[2], 0))
            rotate!(mp, qrotation(Vec3f(0,0,1), -0.5pi))
        elseif placement in (:below, :down, :bottom)
            translate!(mp, Vec3f(o[1] + 0.5w[1], o[2] + w[2], 0))
            rotate!(mp, Quaternionf(0,0,1,0)) # pi
        elseif placement in (:above, :up, :top)
            translate!(mp, Vec3f(o[1] + 0.5w[1], o[2], 0))
            rotate!(mp, Quaternionf(0,0,0,1)) # 0
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            translate!(mp, Vec3f(o[1] + 0.5w[1], o[2], 0))
            rotate!(mp, Quaternionf(0,0,0,1))
        end
        return
    end

    # Outline

    outline = map(bbox, p.triangle_size, p.placement) do bb, s, placement
        o = origin(bb); w = widths(bb)

        shift = if placement == :left 
            [
                Vec2f(0, 0.5w[2]), Vec2f(0, w[2]), w, Vec2f(w[1], 0.5(w[2] + s)), 
                Vec2f(w[1] + s, 0.5w[2]), Vec2f(w[1], 0.5(w[2] - s)),
                Vec2f(w[1], 0), Vec2f(0), Vec2f(0, 0.5w[2])
            ]
        elseif placement == :right
            [
                Vec2f(0.5w[1], 0), Vec2f(0), Vec2f(0, 0.5(w[2] - s)), 
                Vec2f(-s, 0.5w[2]), Vec2f(0, 0.5(w[2] + s)),
                Vec2f(0, w[2]), w, Vec2f(w[1], 0), Vec2f(0.5w[1], 0)
            ]
        elseif placement in (:below, :down, :bottom)
            [
                Vec2f(0, 0.5w[2]), Vec2f(0, w[2]), Vec2f(0.5 * (w[1] - s), w[2]), 
                Vec2f(0.5w[1], w[2]+s), Vec2f(0.5 * (w[1] + s), w[2]), 
                w, Vec2f(w[1], 0), Vec2f(0), Vec2f(0, 0.5w[2])
            ]
        elseif placement in (:above, :up, :top)
            [
                Vec2f(0, 0.5w[2]), Vec2f(0, w[2]), w, Vec2f(w[1], 0), 
                Vec2f(0.5 * (w[1] + s), 0), Vec2f(0.5w[1], -s), 
                Vec2f(0.5 * (w[1] - s), 0), Vec2f(0), Vec2f(0, 0.5w[2])
            ]
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            [
                Vec2f(0), Vec2f(0, w[2]), w, Vec2f(w[1], 0), 
                Vec2f(0.5 * (w[1] + s), 0), Vec2f(0.5w[1], -s), 
                Vec2f(0.5 * (w[1] - s), 0), Vec2f(0)
            ]
        end
        
        for i in eachindex(shift)
            shift[i] = shift[i] + o
        end

        return shift
    end

    lines!(
        p, outline, 
        color = p.outline_color, space = :pixel, 
        linewidth = p.outline_linewidth, linestyle = p.outline_linestyle,
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable
    )

    # Text

    text_offset = map(p.offset, textpadding, p.triangle_size, p.placement) do o, pad, ts, placement
        l, r, b, t = pad

        if placement == :left 
            return Vec2f(-o - r - ts, 0)
        elseif placement == :right
            return Vec2f(o + l + ts, 0)
        elseif placement in (:below, :down, :bottom)
            return Vec2f(0, -o - t - ts)
        elseif placement in (:above, :up, :top)
            return Vec2f(0, o + b + ts)
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return Vec2f(0, o + b + ts)
        end
    end

    text_align = map(p.placement) do placement
        if placement == :left 
            return (:right, :center)
        elseif placement == :right
            return (:left, :center)
        elseif placement in (:below, :down, :bottom)
            return (:center, :top)
        elseif placement in (:above, :up, :top)
            return (:center, :bottom)
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return (:center, :bottom)
        end
    end

    tp = text!(
        p, p[1], text = p[2], justification = p.justification,
        align = text_align, offset = text_offset, textsize = p.textsize,
        color = p.textcolor, font = p.font, fxaa = false,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor,
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable
    )

    onany(
            scene.camera.projectionview, scene.camera.resolution, 
            p[1], p[2], text_align, text_offset, textpadding
        ) do pv, res, p, s, align, o, pad
        l, r, b, t = pad
        bb = Rect2f(boundingbox(tp)) + o
        bbox[] = Rect2f(origin(bb) .- (l, b), widths(bb) .+ (l+r, b+t))
        return nothing
    end

    notify(p[1])

    return p
end
