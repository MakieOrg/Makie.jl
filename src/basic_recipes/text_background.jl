"""
    textbackground(text_plot)


"""
@recipe TextLabel begin
    # TODO: consider using one depth shift and handling per-element shift internally
    # Poly background
    """
    Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`.
    A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates.
    Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors.
    One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.
    """
    background_color = @inherit patchcolor
    "Sets the color of the outline around a marker."
    background_strokecolor = :black
    "Sets the width of the outline."
    background_strokewidth = 1
    """
    Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    background_linestyle = nothing
    background_linecap = @inherit linecap
    background_joinstyle = @inherit joinstyle
    background_miter_limit = @inherit miter_limit
    background_fxaa = false
    background_shading = NoShading

    # """
    # Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.
    # """
    # background_stroke_depth_shift = -1.0f-5
    # "adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw)."
    # background_depth_shift = -1.0f-5
    background_stroke_alpha = 1.0
    background_alpha = 1.0


    # Text
    "Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors."
    text_color = @inherit textcolor
    "Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file"
    font = @inherit font
    "Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`."
    fonts = @inherit fonts
    "Sets the color of the outline around a marker."
    text_strokecolor = (:black, 0.0)
    "Sets the width of the outline around a marker."
    text_strokewidth = 0
    "Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions."
    align = (:left, :bottom)
    "Rotates text around the given position"
    text_rotation = 0.0
    "The fontsize in units depending on `markerspace`."
    fontsize = @inherit fontsize
    "Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`."
    justification = automatic
    "The lineheight multiplier."
    lineheight = 1.0
    # "Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs."
    # markerspace = :pixel
    # "Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)"
    # transform_marker = false
    "Sets the color of the glow effect around the text."
    glowcolor = (:black, 0.0)
    "Sets the size of a glow effect around the text."
    glowwidth = 0.0
    "The offset of the text from the given position in `markerspace` units."
    offset = (0.0, 0.0)
    "Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping."
    word_wrap_width = -1
    text_alpha = 1.0
    # "adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw)."
    # text_depth_shift = 0.0f0
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
    clip_planes = automatic


    "background object to place behind text"
    shape = Rect2f(-1, -1, 2, 2)
    "Limits of background which should be transformed to match the text boundingbox"
    shape_limits = Rect2f(-1, -1, 2, 2)
    "left-right-bottom-top padding"
    pad = Vec4f(2)
    "Should the aspect ratio of the background change?"
    keep_aspect = false
    cornerradius = 0.0
    cornersegments = 10

    draw_on_top = true

    depth_shift = 0.0
end

function convert_arguments(::Type{<: TextLabel}, pos::VecTypes, text::AbstractString)
    return ([pos], [text])
end

function plot!(plot::TextLabel{<: Tuple{<: AbstractVector{<: VecTypes{Dim}}, <: AbstractVector{String}}}) where {Dim}
    # @assert length(plot[1][]) < 2 || allequal(p -> p.markerspace[], plot[1][]) "All text plots must have the same markerspace."

    transformed_shape = Observable(PolyElements[plot.shape[]])

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
        linecap = plot.background_linecap,
        joinstyle = plot.background_joinstyle,
        miter_limit = plot.background_miter_limit,
        shading = plot.background_shading,
        # stroke_alpha = plot.background_stroke_alpha, # TODO: doesn't exist in poly
        alpha = plot.background_alpha,
        stroke_depth_shift = plot.depth_shift,
        # move poly slightly behind - this is unnecessary atm because we also
        # translate!(). Maybe useful when generalizing to 3D though
        depth_shift = map(x -> x + 1f-5, plot, plot.depth_shift),
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
    )

    tp = text!(
        plot, plot[1], text = plot[2],
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
        space = plot.space,
        inspector_label = plot.inspector_label,
        inspector_clear = plot.inspector_clear,
        inspector_hover = plot.inspector_hover,
        clip_planes = plot.clip_planes,
    )



    scene = Makie.parent_scene(plot)

    # since CairoMakie consider translation/model in render order we should use
    # translate!() to order these plots. This is wrong in 3D
    on(plot, plot.draw_on_top, update = true) do draw_on_top
        if draw_on_top
            if !is_translation_scale_matrix(camera(scene).projectionview[])
                error("draw_on_top = true requires a 2D Scene/Axis")
            end
            if Dim != 2
                error("draw_on_top = true requires 2D text positions")
            end
            translate!(tp, 0, 0, 10_000)
        else
            translate!(tp, 0, 0, 0)
        end
        return Consume(false)
    end

    native_tp = tp.plots[1]

    # TODO: vector
    translation_scale_z = map(
            plot,
            plot.shape_limits, plot.pad, plot.keep_aspect,
            camera(scene).projectionview, viewport(scene),
            native_tp.transformation.model, native_tp.transformation.transform_func,
            native_tp.position, native_tp.converted[1], native_tp.strokewidth, native_tp.glowwidth,
            native_tp.space, native_tp.markerspace
        ) do limits, (l, r, b, t), keep_aspect, args...

        bbox = boundingbox(native_tp, native_tp.markerspace[])
        z = minimum(bbox)[3]
        bbox = Rect2d(minimum(bbox)[Vec(1,2)] .- (l, b), widths(bbox)[Vec(1,2)] .+ (l, b) .+ (r, t))
        scale = widths(bbox) ./ widths(limits)
        if keep_aspect
            scale = Vec2d(maximum(s))
        end
        # translate center for keep_aspect = true
        translation = minimum(bbox) + 0.5 * widths(bbox) .- scale .* (minimum(limits) + 0.5 * widths(limits))
        # return (to_ndim(Point3d, translation, z), scale)
        return (translation, scale, z)
    end

    map!(
            plot, transformed_shape,
            plot.shape, plot.cornerradius, plot.cornersegments, translation_scale_z
        ) do shape, cornerradius, cornersegments, (translation, scale, z)

        if shape isa Rect && cornerradius > 0
            mini = scale .* minimum(shape) .+ translation[Vec(1,2)]
            ws = scale .* widths(shape)
            verts = roundedrectvertices(Rect(mini, ws), cornerradius, cornersegments)
            mesh = poly_convert(verts)
        else
            verts = convert_arguments(PointBased(), shape)[1]
            verts = [scale .* p .+ translation[Vec(1,2)] for p in verts]
            mesh = poly_convert(verts)
        end
        return PolyElements[mesh]
    end

    on(plot, translation_scale_z, update = true) do (_, __, z)
        translate!(pp, 0, 0, z-1)
        return Consume(false)
    end

    return plot
end

# TODO: maybe back-transform?
data_limits(p::TextLabel) = data_limits(p.plots[2])
boundingbox(p::TextLabel, space::Symbol) = boundingbox(p.plots[2], space)