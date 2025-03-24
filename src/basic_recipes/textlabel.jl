"""
    textbackground(text_plot)


"""
@recipe TextLabel begin
    # text-like args interface
    "Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`."
    text = ""
    "Deprecated: Specifies the position of the text. Use the positional argument to `text` instead."
    position = (0, 0)

    # TODO: does not include color mapping for text, backgrounds and background strokes

    # Poly background
    """
    Sets the color of the background. Can be a `Vector{<:Colorant}` for per vertex colors, a single `Colorant`
    or an `<: AbstractPattern` to cover the poly with a regular pattern, e.g. for hatching.
    """
    background_color = @inherit patchcolor
    "Sets the color of the outline around the background"
    background_strokecolor = :black
    "Sets the width of the outline."
    background_strokewidth = 1
    """
    Sets the dash pattern of the outline. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    background_linestyle = nothing
    """
    Controls the rendering of outline corners. Options are `:miter` for sharp corners,
    `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    background_joinstyle = @inherit joinstyle
    "Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`."
    background_miter_limit = @inherit miter_limit
    "Controls whether the background renders with fxaa (anti-aliasing, GLMakie only). This is set to `false` by default to prevent artifacts around text."
    background_fxaa = false
    "Controls whether the background reacts to light."
    background_shading = NoShading
    "Sets the alpha value (opaqueness) of the background outline."
    background_stroke_alpha = 1.0
    "Sets the alpha value (opaqueness) of the background."
    background_alpha = 1.0

    # Text
    "Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}` or one colorant for the whole text."
    text_color = @inherit textcolor
    "Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file"
    font = @inherit font
    "Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`."
    fonts = @inherit fonts
    # Note: handling these in arbitrary markerspace is difficult, because they
    #       always act in pixel space.
    "Sets the color of the outline around text."
    text_strokecolor = (:black, 0.0)
    "Sets the width of the outline around text."
    text_strokewidth = 0
    "Sets the color of the glow effect around text."
    glowcolor = (:black, 0.0)
    "Sets the size of a glow effect around text."
    glowwidth = 0.0

    "Sets the alignment of the string with respect to `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions."
    align = (:left, :bottom)
    "Rotates the text around the given position. This affects the size of the textlabel but not its rotation"
    text_rotation = 0.0
    # "The fontsize in units depending on `markerspace`."
    "The fontsize in pixel units."
    fontsize = @inherit fontsize
    "Sets the alignment of text with respect to its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`."
    justification = automatic
    "The lineheight multiplier."
    lineheight = 1.0
    # TODO: Generalize markerspace
    # "Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs."
    # markerspace = :pixel
    # "Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)"
    # transform_marker = false
    "The offset of the textlabel from the given position in `markerspace` units."
    offset = (0.0, 0.0)
    "Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping."
    word_wrap_width = -1
    "Sets the alpha value (opaqueness) of the text."
    text_alpha = 1.0
    "Controls whether the text renders with fxaa (anti-aliasing, GLMakie only). Setting this to true will reduce text quality."
    text_fxaa = false

    # Generic
    transformation = automatic
    "Controls whether the plot will be rendered or not."
    visible = true
    "Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency."
    transparency = false
    "Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends"
    overdraw = false
    "Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`."
    inspectable = @inherit inspectable
    "sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs."
    space = :data
    # "adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only)."
    # fxaa = true
    "Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector."
    inspector_label = automatic
    "Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector."
    inspector_clear = automatic
    "Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods."
    inspector_hover = automatic
    """
    Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here,
    behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the
    parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.
    """
    clip_planes = Plane3f[]


    """
    Controls the shape of the background. Can be a GeometryPrimitive, mesh or function `(origin, size) -> coordinates`.
    The former two options are automatically rescaled to the padded bounding box of the rendered text. By default (0, 0)
    will be the lower left corner and (1, 1) the upper right corner of the padded bounding box. See `shape_limits`.
    """
    shape = Rect2f(0, 0, 1, 1)
    """
    Sets the coordinates in `shape` space that should be transformed to match the size of the text bounding box.
    For example, `shape_limits = Rect2f(-1, -1, 2, 2)` results in transforming (-1, 1) to the lower left corner
    of the padded text bounding box and (1, 1) to the upper right corner. If the `shape` contains coordinates
    outside this range, they will rendered outside the padded text bounding box.
    """
    shape_limits = Rect2f(0, 0, 1, 1)
    # TODO: Generalize markerspace
    "Sets the padding between the text bounding box and background shape."
    pad = Vec4f(2)
    "Controls whether the aspect ratio of the background shape is kept during rescaling"
    keep_aspect = false
    "Sets the corner radius when given a Rect2 background shape."
    cornerradius = 0.0
    "Sets the number of vertices involved in a rounded corner. Must be at least 2."
    cornervertices = 10
    "Controls whether the textlabel is drawn in front (true, default) or at a depth appropriate to its position."
    draw_on_top = true
    "Adjusts the depth value of the textlabel after all other transformations, i.e. in clip space where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw)."
    depth_shift = 0.0
end

convert_arguments(::Type{<: TextLabel}, args...) = convert_arguments(Text, args...)
convert_arguments(::Type{<: TextLabel}, x, y, z::AbstractArray{<:Real}) = convert_arguments(PointBased(), x, y, z)
convert_arguments(::Type{<: TextLabel}, p::VecTypes, str) = ([(str, p)],)
convert_arguments(::Type{<: TextLabel}, x, y, strs) = (map(tuple, strs, convert_arguments(PointBased(), x, y)[1]), )
convert_arguments(::Type{<: TextLabel}, x, y, z, strs) = (map(tuple, strs, convert_arguments(PointBased(), x, y, z)[1]), )

function plot!(plot::TextLabel{<:Tuple{<:AbstractString}})
    attrs = copy(plot.attributes) # TODO: does this need to be a copy?
    pop!(attrs, :calculated_colors, nothing)
    textlabel!(plot, plot.position; attrs..., text = plot[1])
    plot
end

function plot!(plot::TextLabel{<:Tuple{<:AbstractArray{<:AbstractString}}})
    attrs = copy(plot.attributes)
    pop!(attrs, :calculated_colors, nothing)
    textlabel!(plot, plot.position; attrs..., text = plot[1])
    plot
end

function plot!(plot::TextLabel{<:Tuple{<:AbstractArray{<:Tuple{<:Any, <:VecTypes}}}})
    strings_and_positions = plot[1]

    strings = Observable{Vector{Any}}(first.(strings_and_positions[]))

    positions = Observable(
        Point3d[to_ndim(Point3d, last(x), 0) for x in  strings_and_positions[]] # avoid Any for zero elements
    )

    attrs = plot.attributes
    pop!(attrs, :position)
    pop!(attrs, :calculated_colors, nothing)
    pop!(attrs, :text)

    textlabel!(plot, positions, text = strings; attrs...)

    # update both text and positions together
    on(plot, strings_and_positions) do str_pos
        strs = first.(str_pos)
        poss = to_ndim.(Ref(Point3d), last.(str_pos), 0)

        strings_unequal = strings.val != strs
        pos_unequal = positions.val != poss
        strings_unequal && (strings.val = strs)
        pos_unequal && (positions.val = poss)
        # Check for equality very important, otherwise we get an infinite loop
        strings_unequal && notify(strings)
        pos_unequal && notify(positions)

        return
    end
    plot
end


function text_boundingbox_transforms(plot, positions, glyph_collections::Vector, limits, pad, keep_aspect)
    (l, r, b, t) = pad

    cam = Ref(camera(parent_scene(plot)))
    transformed = apply_transform_and_model(plot, positions)
    ms_positions = Makie.project.(cam, plot.space[], plot.markerspace[], transformed)
    rotations = to_rotation(plot.rotation[])

    transformations = Vector{Tuple{Vec2d, Vec2d, Float64}}(undef, length(glyph_collections))

    for i in eachindex(glyph_collections)
        bbox = string_boundingbox(glyph_collections[i], ms_positions[i], sv_getindex(rotations, i))
        z = minimum(bbox)[3]
        bbox = Rect2d(minimum(bbox)[Vec(1,2)] .- (l, b), widths(bbox)[Vec(1,2)] .+ (l, b) .+ (r, t))
        scale = widths(bbox) ./ widths(limits)
        if keep_aspect
            scale = Vec2d(maximum(scale))
        end
        # translate center for keep_aspect = true
        translation = minimum(bbox) + 0.5 * widths(bbox) .- scale .* (minimum(limits) + 0.5 * widths(limits))

        transformations[i] = (translation, scale, z)
    end

    return transformations
end


function plot!(plot::TextLabel{<: Tuple{<: AbstractVector{<: Point}}})
    # @assert length(plot[1][]) < 2 || allequal(p -> p.markerspace[], plot[1][]) "All text plots must have the same markerspace."

    transformed_shape = Observable(PolyElements[])

    # FXAA generates artifacts if:
    # mesh has fxaa = true and text/lines has false
    # and the luma/brightness difference between text_color/strokecolor and background_color is low enough

    # The defaults use fxaa = false to remove artifacting and use an opaque
    # stroke to hide the pixelated border.

    pp = poly!(
        plot, transformed_shape,
        color = plot.background_color,
        # hide pixelated mesh behind outline of the same color by default
        strokecolor = plot.background_strokecolor,
        strokewidth = plot.background_strokewidth,
        linestyle = plot.background_linestyle,
        joinstyle = plot.background_joinstyle,
        miter_limit = plot.background_miter_limit,
        shading = plot.background_shading,
        # stroke_alpha = plot.background_stroke_alpha, # TODO: doesn't exist in poly
        alpha = plot.background_alpha,
        stroke_depth_shift = plot.depth_shift,
        # move poly slightly behind - this is unnecessary atm because we also
        # translate!(). Maybe useful when generalizing to 3D though
        depth_shift = map(x -> x + 1f-7, plot, plot.depth_shift),
        fxaa = plot.background_fxaa,
        visible = plot.visible,
        transparency = plot.transparency,
        overdraw = plot.overdraw,
        inspectable = plot.inspectable,
        space = :pixel, # TODO: variable markerspace
        inspector_label = plot.inspector_label,
        inspector_clear = plot.inspector_clear,
        inspector_hover = plot.inspector_hover,
        clip_planes = plot.clip_planes,
        transformation = Transformation(), # already processed in bbox calculation
    )

    # Transforming to pixel space so we can use translate!() for z ordering. If
    # CairoMakie would consider clip space w/ depth_shift for z ordering we could
    # rely on that instead.
    scene = Makie.parent_scene(plot)
    pixel_pos = Observable(Point2f[])
    pixel_z = Observable(0.0)
    onany(
            plot, plot[1],
            camera(scene).projectionview, viewport(scene),
            plot.model, plot.transformation.transform_func,
            plot.space, plot.draw_on_top, #, native_tp.markerspace,
            update = true
        ) do positions, pv, vp, m, tf, s, draw_on_top #, ms
        cam = Ref(camera(parent_scene(plot)))
        transformed = apply_transform_and_model(plot, positions)
        # Makie.project.(cam, plot.space[], plot.markerspace[], transformed)
        px_pos = Makie.project.(cam, plot.space[], :pixel, transformed)
        pixel_pos[] = Point2f.(px_pos)
        pixel_z[] = draw_on_top ? 0 : px_pos[1][3] # See <1>
        return Consume(false)
    end

    tp = text!(
        plot, pixel_pos, text = plot.text,
        color = plot.text_color,
        strokecolor = plot.text_strokecolor,
        strokewidth = plot.text_strokewidth,
        alpha = plot.text_alpha,
        rotation = plot.text_rotation,
        font = plot.font,
        fonts = plot.fonts,
        align = plot.align,
        fontsize = plot.fontsize,
        justification = plot.justification,
        lineheight = plot.lineheight,
        glowcolor = plot.glowcolor,
        glowwidth = plot.glowwidth,
        offset = plot.offset,
        word_wrap_width = plot.word_wrap_width,
        depth_shift = plot.depth_shift,
        fxaa = plot.text_fxaa,
        visible = plot.visible,
        transparency = plot.transparency,
        overdraw = plot.overdraw,
        inspectable = plot.inspectable,
        # TODO:: generalize markerspace
        # - if we pre-transform we should go to markerspace and set space = plot.markerspace
        # - if we don't we should set space = plot.space[] and markerspace = plot.markerspace
        space = :pixel,
        inspector_label = plot.inspector_label,
        inspector_clear = plot.inspector_clear,
        inspector_hover = plot.inspector_hover,
        clip_planes = plot.clip_planes,
    )

    # since CairoMakie consider translation/model in render order we should use
    # translate!() to order these plots. (This does not work in 3D with
    # space = :data)
    onany(plot, plot.draw_on_top, pixel_z, update = true) do draw_on_top, z
        translate!(tp, 0, 0, draw_on_top ? 10_000 : z + 0.01)
        return Consume(false)
    end

    native_tp = tp.plots[1]

    # TODO: vector
    translation_scale_z = map(
            plot,
            plot.shape_limits, plot.pad, plot.keep_aspect,
            pixel_pos, native_tp.converted[1], pixel_z, plot.offset,
            # these are difficult because they are not in markerspace but always pixel space...
            native_tp.strokewidth, native_tp.glowwidth,
            native_tp.space, native_tp.markerspace
        ) do limits, pad, keep_aspect, positions, glyph_collections, z, offset, sw, gw, args...

        pos = [to_ndim(Point3f, p, z) + to_ndim(Point3f, sv_getindex(offset, i), 0) for (i, p) in enumerate(positions)]
        return text_boundingbox_transforms(
            native_tp, pos, glyph_collections,
            limits, to_lrbt_padding(pad) .+ to_lrbt_padding(sw + gw), keep_aspect
        )
    end

    map!(
        plot, transformed_shape,
        plot.shape, plot.cornerradius, plot.cornervertices, translation_scale_z
    ) do shape, cornerradius, cornervertices, transformations

        elements = Vector{PolyElements}(undef, length(transformations))

        for i in eachindex(transformations)
            translation, scale, z = transformations[i]

            if shape isa Rect && cornerradius > 0
                mini = scale .* minimum(shape) .+ translation[Vec(1,2)]
                ws = scale .* widths(shape)
                element = roundedrectvertices(Rect(mini, ws), cornerradius, cornervertices)
            elseif hasmethod(shape, (Vec2d, Vec2d))
                element = shape(translation, scale)
            else
                verts = convert_arguments(PointBased(), shape)[1]
                element = Point2f[scale .* p .+ translation[Vec(1,2)] for p in verts]
            end

            elements[i] = element
        end

        return elements
    end

    onany(plot, plot.draw_on_top, translation_scale_z, update = true) do draw_on_top, transforms
        # TODO: Because CairoMakie only considers transformations in its depth sorting
        #       we are forced to rely on translate!() for it here. This means we can't
        #       do per-element z sorting. <1>
        z = transforms[1][3]
        translate!(pp, 0, 0, (draw_on_top ? 10_000 : z) - 0.01)
        return Consume(false)
    end

    return plot
end

# TODO: maybe back-transform?
data_limits(p::TextLabel) = data_limits(p.plots[end])
data_limits(p::TextLabel{<: Tuple{<: AbstractVector{<: Point}}}) = Rect3d(p[1][])
boundingbox(p::TextLabel, space::Symbol) = apply_transform_and_model(p, data_limits(p))