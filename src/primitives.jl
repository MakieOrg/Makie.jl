################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Lines, LineSegments})
    fields = @get_attribute(primitive, (color, linewidth, linestyle))
    linestyle = AbstractPlotting.convert_attribute(linestyle, AbstractPlotting.key"linestyle"())
    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]

    isempty(positions) && return

    # workaround for a LineSegments object created from a GLNormalMesh
    # the input argument is a view of points using faces, which results in
    # a vector of tuples of two points. we convert those to a list of points
    # so they don't trip up the rest of the pipeline
    # TODO this shouldn't be necessary anymore!
    if positions isa SubArray{<:Point3, 1, P, <:Tuple{Array{<:AbstractFace}}} where P
        positions = let
            pos = Point3f0[]
            for tup in positions
                push!(pos, tup[1])
                push!(pos, tup[2])
            end
            pos
        end
    end

    projected_positions = project_position.(Ref(scene), positions, Ref(model))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately

    # The linestyle can be set globally, as we do here.
    # However, there is a discrepancy between AbstractPlotting
    # and Cairo when it comes to linestyles.
    # For AbstractPlotting, the linestyle array is cumulative,
    # and defines the "absolute" endpoints of segments.
    # However, for Cairo, each value provides the length of
    # alternate "on" and "off" portions of the stroke.
    # Therefore, we take the diff of the given linestyle,
    # to convert the "absolute" coordinates into "relative" ones.
    if !isnothing(linestyle) && !(linewidth isa AbstractArray)
        Cairo.set_dash(ctx, diff(Float64.(linestyle)) .* linewidth)
    end
    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short

        # we can hide the gaps by setting the line cap to round
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
        draw_multi(
            primitive, ctx,
            projected_positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(primitive, ctx, projected_positions)
    end
    nothing
end

function draw_single(primitive::Lines, ctx, positions)
    n = length(positions)
    @inbounds for i in 1:n
        p = positions[i]
        # only take action for non-NaNs
        if !isnan(p)
            # new line segment at beginning or if previously NaN
            if i == 1 || isnan(positions[i-1])
                Cairo.move_to(ctx, p...)
            else
                Cairo.line_to(ctx, p...)
                # complete line segment at end or if next point is NaN
                if i == n || isnan(positions[i+1])
                    Cairo.stroke(ctx)
                end
            end
        end
    end
end

function draw_single(primitive::LineSegments, ctx, positions)
    @assert iseven(length(positions))
    @inbounds for i in 1:length(positions)
        if iseven(i)
            Cairo.line_to(ctx, positions[i]...)
            Cairo.stroke(ctx)
        else
            Cairo.move_to(ctx, positions[i]...)
        end
    end
end

# if linewidth is not an array
function draw_multi(primitive, ctx, positions, colors::AbstractArray, linewidth, dash)
    draw_multi(primitive, ctx, positions, colors, [linewidth for c in colors], dash)
end

# if color is not an array
function draw_multi(primitive, ctx, positions, color, linewidths::AbstractArray, dash)
    draw_multi(primitive, ctx, positions, [color for l in linewidths], linewidths, dash)
end

function draw_multi(primitive::Union{Lines, LineSegments}, ctx, positions, colors::AbstractArray, linewidths::AbstractArray, dash)
    if primitive isa LineSegments
        @assert iseven(length(positions))
    end
    @assert length(positions) == length(colors)
    @assert length(linewidths) == length(colors)

    iterator = if primitive isa Lines
        1:length(positions)-1
    elseif primitive isa LineSegments
        1:2:length(positions)
    end

    for i in iterator
        if isnan(positions[i+1]) || isnan(positions[i])
            continue
        end
        Cairo.move_to(ctx, positions[i]...)

        Cairo.line_to(ctx, positions[i+1]...)
        if linewidths[i] != linewidths[i+1]
            error("Cairo doesn't support two different line widths ($(linewidths[i]) and $(linewidths[i+1])) at the endpoints of a line.")
        end
        Cairo.set_line_width(ctx, linewidths[i])
        !isnothing(dash) && Cairo.set_dash(ctx, dash .* linewidths[i])
        c1 = colors[i]
        c2 = colors[i+1]
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i+1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
end

################################################################################
#                                   Scatter                                    #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Scatter)
    fields = @get_attribute(primitive, (color, markersize, strokecolor, strokewidth, marker, marker_offset, rotations))
    @get_attribute(primitive, (transform_marker,))

    ctx = screen.context
    model = primitive[:model][]
    positions = primitive[1][]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4f0(I)

    font = to_font(to_value(get(primitive, :font, AbstractPlotting.defaultfont())))

    colors = if color isa AbstractArray{<: Number}
        numbers_to_colors(color, primitive)
    else
        color
    end

    broadcast_foreach(primitive[1][], colors, markersize, strokecolor,
                      strokewidth, marker, marker_offset, primitive.rotations[]) do point, col,
                          markersize, strokecolor, strokewidth, marker, mo, rotation

        # if we give size in pixels, the size is always equal to that value
        is_pixelspace = haskey(primitive, :markerspace) && primitive.markerspace[] == AbstractPlotting.Pixel
        scale = if is_pixelspace
            AbstractPlotting.to_2d_scale(markersize)
        else
            # otherwise calculate a scaled size
            project_scale(scene, markersize, size_model)
        end
        offset = if is_pixelspace
            AbstractPlotting.to_2d_scale(mo)
        else
            project_scale(scene, mo, size_model)
        end

        pos = project_position(scene, point, model)

        isnan(pos) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        m = convert_attribute(marker, key"marker"(), key"scatter"())
        if m isa Char
            draw_marker(ctx, m, best_font(m, font), pos, scale, strokecolor, strokewidth, offset, rotation)
        else
            draw_marker(ctx, m, pos, scale, strokecolor, strokewidth, offset, rotation)
        end
    end
    nothing
end


function draw_marker(ctx, marker::Circle, pos, scale, strokecolor, strokewidth, marker_offset, rotation)

    marker_offset = marker_offset + scale ./ 2

    pos += Point2f0(marker_offset[1], -marker_offset[2])

    # Cairo.scale(ctx, scale...)
    Cairo.move_to(ctx, pos[1] + scale[1]/2, pos[2])
    Cairo.arc(ctx, pos[1], pos[2], scale[1]/2, 0, 2*pi)
    Cairo.fill_preserve(ctx)

    sc = to_color(strokecolor)

    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
end

function draw_marker(ctx, marker::Char, font, pos, scale, strokecolor, strokewidth, marker_offset, rotation)

    Cairo.save(ctx)

    # Marker offset is meant to be relative to the
    # bottom left corner of the box centered at
    # `pos` with sides defined by `scale`, but
    # this does not take the character's dimensions
    # into account.
    # Here, we reposition the marker offset to be
    # relative to the center of the char.
    marker_offset = marker_offset .+ scale ./ 2

    cairoface = set_ft_font(ctx, font)

    charextent = AbstractPlotting.FreeTypeAbstraction.internal_get_extent(font, marker)
    inkbb = AbstractPlotting.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    inkbb_scaled = FRect2D(origin(inkbb) .* scale, widths(inkbb) .* scale)

    # flip y for the centering shift of the character because in Cairo y goes down
    centering_offset = [1, -1] .* (-origin(inkbb_scaled) .- 0.5 .* widths(inkbb_scaled))
    # this is the origin where we actually have to place the glyph so it can be centered
    charorigin = pos .+ Vec2f0(marker_offset[1], -marker_offset[2])
    old_matrix = get_font_matrix(ctx)
    set_font_matrix(ctx, scale_matrix(scale...))

    # First, we translate to the point where the
    # marker is supposed to go.
    Cairo.translate(ctx, charorigin...)
    # Then, we rotate the context by the
    # appropriate amount,
    Cairo.rotate(ctx, to_2d_rotation(rotation))
    # and apply a centering offset to account for
    # the fact that text is shown from the (relative)
    # bottom left corner.
    Cairo.translate(ctx, centering_offset...)

    Cairo.move_to(ctx, 0, 0)
    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    # stroke
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

    set_font_matrix(ctx, old_matrix)
    Cairo.restore(ctx)

end


function draw_marker(ctx, marker::Union{Rect, Type{<: Rect}}, pos, scale, strokecolor, strokewidth, marker_offset, rotation)
    s2 = if marker isa Type{Rect}
        Point2(scale[1], -scale[2])
    else
        Point2((widths(marker) .* scale .* (1, -1))...)
    end

    offset = marker_offset .+ scale ./ 2

    pos += Point2f0(offset[1], -offset[2])

    Cairo.move_to(ctx, pos...)
    Cairo.rotate(ctx, to_2d_rotation(rotation))
    Cairo.rectangle(ctx, 0, 0, s2...)
    Cairo.fill_preserve(ctx);
    if strokewidth > 0.0
        sc = to_color(strokecolor)
        Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
        Cairo.set_line_width(ctx, Float64(strokewidth))
        Cairo.stroke(ctx)
    end
end


################################################################################
#                                     Text                                     #
################################################################################

function p3_to_p2(p::Point3{T}) where T
    if p[3] == 0 || isnan(p[3])
        Point2{T}(p[1:2]...)
    else
        error("Can't reduce Point3 to Point2 with nonzero third component $(p[3]).")
    end
end

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Text)
    ctx = screen.context
    @get_attribute(primitive, (textsize, color, font, rotation, model, space))
    txt = to_value(primitive[1])
    position = primitive.attributes[:position][]
    # use cached glyph info
    glyphlayouts = primitive._glyphlayout[]

    draw_string(scene, ctx, txt, position, glyphlayouts, textsize, color, font, rotation, model,  space)

    nothing
end

function draw_string(scene, ctx, strings::AbstractArray, positions::AbstractArray, glyphlayouts, textsize, color, font, rotation, model::SMatrix, space)

    # TODO: why is the Ref around model necessary? doesn't broadcast_foreach handle staticarrays matrices?
    broadcast_foreach(strings, positions, glyphlayouts, textsize, color, font, rotation,
        Ref(model), space) do str, pos, glayout, ts, c, f, ro, mo, sp

        draw_string(scene, ctx, str, pos, glayout, ts, c, f, ro, mo, sp)
    end
end

function draw_string(scene, ctx, str::String, position::VecTypes, glyphlayout, textsize, color, font, rotation, model, space)

    glyphoffsets = glyphlayout.origins


    Cairo.save(ctx)
    cairoface = set_ft_font(ctx, font)
    Cairo.set_source_rgba(ctx, rgbatuple(color)...)
    old_matrix = get_font_matrix(ctx)


    for (goffset, char) in zip(glyphoffsets, str)

        char in ('\r', '\n') && continue

        if space == :data
            # in data space, the glyph offsets are just added to the string positions
            # and then projected

            # glyph position in data coordinates (offset has rotation applied already)
            gpos_data = to_ndim(Point3f0, position, 0) .+ goffset

            scale3 = textsize isa Number ? Point3f0(textsize, textsize, 0) : to_ndim(Point3f0, textsize, 0)

            # this could be done better but it works at least

            # the CairoMatrix is found by transforming the right and up vector
            # of the character into screen space and then subtracting the projected
            # origin. The resulting vectors give the directions in which the character
            # needs to be stretched in order to match the 3D projection

            xvec = rotation * (scale3[1] * Point3f0(1, 0, 0))
            yvec = rotation * (scale3[2] * Point3f0(0, -1, 0))

            gproj = project_position(scene, gpos_data, Mat4f0(I))
            xproj = project_position(scene, gpos_data + xvec, Mat4f0(I))
            yproj = project_position(scene, gpos_data + yvec, Mat4f0(I))

            xdiff = xproj - gproj
            ydiff = yproj - gproj

            mat = Cairo.CairoMatrix(
                xdiff[1], xdiff[2],
                ydiff[1], ydiff[2],
                0, 0,
            )

            Cairo.save(ctx)
            Cairo.move_to(ctx, gproj...)
            set_font_matrix(ctx, mat)

            # Cairo.rotate(ctx, to_2d_rotation(rotation))
            Cairo.show_text(ctx, string(char))
            Cairo.restore(ctx)

        elseif space == :screen
            # in screen space, the glyph offsets are added after projecting
            # the string position into screen space
            glyphpos = project_position(
                scene,
                position,
                Mat4f0(I)) .+ p3_to_p2(goffset) .* (1, -1) # flip for Cairo
            # and the scale is just taken as is
            scale = length(textsize) == 2 ? textsize : SVector(textsize, textsize)

            Cairo.save(ctx)
            Cairo.move_to(ctx, glyphpos...)
            # TODO this only works in 2d
            mat = scale_matrix(scale...)
            set_font_matrix(ctx, mat)
            Cairo.rotate(ctx, to_2d_rotation(rotation))

            Cairo.show_text(ctx, string(char))
            Cairo.restore(ctx)
        else
            error()
        end
    end

    cairo_font_face_destroy(cairoface)
    set_font_matrix(ctx, old_matrix)
    Cairo.restore(ctx)

    nothing
end

################################################################################
#                                Heatmap, Image                                #
################################################################################

function draw_atomic(scene::Scene, screen::CairoScreen, primitive::Union{Heatmap, Image})
    ctx = screen.context
    image = primitive[3][]
    x, y = primitive[1][], primitive[2][]
    model = primitive[:model][]
    imsize = (extrema_nan(x), extrema_nan(y))

    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation
    xy = project_position(scene, Point2f0(first.(imsize)), model)
    xymax = project_position(scene, Point2f0(last.(imsize)), model)


    w, h = xymax .- xy
    interp = to_value(get(primitive, :interpolate, true))

    # theoretically, we could restrict the non-interpolation vector graphics hack to actual vector
    # graphics backends, but it's not directly visible from screen.surface what type we have

    if interp
        # FILTER_BEST doesn't work reliably with png backend, GAUSSIAN is not implemented
        interp_flag = Cairo.FILTER_BILINEAR

        s = to_cairo_image(image, primitive)
        Cairo.rectangle(ctx, xy..., w, h)
        Cairo.save(ctx)
        Cairo.translate(ctx, xy...)
        Cairo.scale(ctx, w / s.width, h / s.height)
        Cairo.set_source_surface(ctx, s, 0, 0)
        p = Cairo.get_source(ctx)
        # Set filter doesn't work!?
        Cairo.pattern_set_filter(p, interp_flag)
        Cairo.fill(ctx)
        Cairo.restore(ctx)

    else
        colors = to_rgba_image(image, primitive)

        cellw = w / size(image, 1)
        cellh = h / size(image, 2)

        ni, nj = size(image)
        @inbounds for i in 1:ni, j in 1:nj
            ori = xy + Point2f0((i-1) * cellw, (j-1) * cellh)

            # there are usually white lines between directly adjacent rectangles
            # in vector graphics because of anti-aliasing

            # if we let each cell stick out (bulge) a little bit (half a point) under its neighbors
            # those lines disappear

            # we heuristically only do this if the adjacent cells are fully opaque
            # and if we're not in the last row / column so the overall heatmap doesn't get bigger

            # this should be the most common case by far, though

            xbulge = if i < ni && alpha(colors[i+1, j]) == 1
                0.5
            else
                0.0
            end
            ybulge = if j < nj && alpha(colors[i, j+1]) == 1
                0.5
            else
                0.0
            end

            # we add the bulge in the direction of cellw / cellh in case the axes are reversed
            Cairo.rectangle(ctx, ori..., cellw + sign(cellw) * xbulge, cellh + sign(cellh) * ybulge)
            Cairo.set_source_rgba(ctx, rgbatuple(colors[i, j])...)
            Cairo.fill(ctx)
        end
    end
end


################################################################################
#                                     Mesh                                     #
################################################################################


function draw_atomic(scene::Scene, screen::CairoScreen, primitive::AbstractPlotting.Mesh)
    if scene.camera_controls[] isa Union{Camera2D, AbstractPlotting.PixelCamera}
        draw_mesh2D(scene, screen, primitive)
    else
        if !haskey(primitive, :faceculling)
            primitive[:faceculling] = Node(1e-6)
        end
        draw_mesh3D(scene, screen, primitive)
    end
    return nothing
end

function draw_mesh2D(scene, screen, primitive)
    @get_attribute(primitive, (color,))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value
    ctx = screen.context
    model = primitive.model[]
    mesh = GeometryBasics.mesh(primitive[1][])
    # Priorize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!
    color = hasproperty(mesh, :color) ? mesh.color : color
    vs =  decompose(Point, mesh); fs = decompose(TriangleFace, mesh)
    uv = hasproperty(mesh, :uv) ? mesh.uv : nothing
    pattern = Cairo.CairoPatternMesh()

    cols = per_face_colors(color, colormap, colorrange, nothing, vs, fs, nothing, uv)
    for (f, (c1, c2, c3)) in zip(fs, cols)
        t1, t2, t3 =  project_position.(scene, vs[f], (model,)) #triangle points
        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1...)
        Cairo.mesh_pattern_line_to(pattern, t2...)
        Cairo.mesh_pattern_line_to(pattern, t3...)

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
    end
    Cairo.set_source(ctx, pattern)
    Cairo.close_path(ctx)
    Cairo.paint(ctx)
    return nothing
end

function average_z(positions, face)
    vs = positions[face]
    sum(v -> v[3], vs) / length(vs)
end

function draw_mesh3D(
        scene, screen, primitive;
        mesh = primitive[1][], pos = Vec4f0(0), scale = 1f0
    )
    @get_attribute(primitive, (color, shading, lightposition, ambient, diffuse,
        specular, shininess, faceculling))

    colormap = get(primitive, :colormap, nothing) |> to_value |> to_colormap
    colorrange = get(primitive, :colorrange, nothing) |> to_value
    matcap = get(primitive, :matcap, nothing) |> to_value
    # Priorize colors of the mesh if present
    color = hasproperty(mesh, :color) ? mesh.color : color

    ctx = screen.context

    model = primitive.model[]
    view = scene.camera.view[]
    projection = scene.camera.projection[]
    normalmatrix = get(
        scene.attributes, :normalmatrix, let
            i = SOneTo(3)
            transpose(inv(view[i, i] * model[i, i]))
        end
    )

    # Mesh data
    # transform to view/camera space
    vs = map(coordinates(mesh)) do v
        p4d = to_ndim(Vec4f0, scale .* to_ndim(Vec3f0, v, 0f0), 1f0)
        view * (model * p4d .+ to_ndim(Vec4f0, pos, 0f0))
    end
    fs = faces(mesh)
    uv = hasproperty(mesh, :uv) ? mesh.uv : nothing
    ns = map(n -> normalmatrix * n, normals(mesh))
    cols = per_face_colors(color, colormap, colorrange, matcap, vs, fs, ns, uv)

    # Liight math happens in view/camera space
    if lightposition == :eyeposition
        lightposition = scene.camera.eyeposition[]
    end
    lightpos = (view * to_ndim(Vec4f0, lightposition, 1.0))[Vec(1, 2, 3)]

    # Camera to screen space
    ts = map(vs) do v
        clip = projection * v
        @inbounds begin
            p = (clip ./ clip[4])[Vec(1, 2)]
            p_yflip = Vec2f0(p[1], -p[2])
            p_0_to_1 = (p_yflip .+ 1f0) / 2f0
        end
        p = p_0_to_1 .* scene.camera.resolution[]
        Vec3f0(p[1], p[2], clip[3])
    end

    # Approximate zorder
    zorder = sortperm(fs, by = f -> average_z(ts, f))

    # Face culling
    zorder = filter(i -> any(last.(ns[fs[i]]) .> faceculling), zorder)

    pattern = Cairo.CairoPatternMesh()
    for k in reverse(zorder)
        f = fs[k]
        t1, t2, t3 = ts[f]

        # light calculation
        c1, c2, c3 = if shading
            map(ns[f], vs[f], cols[k]) do N, v, c
                L = normalize(lightpos .- v[Vec(1,2,3)])
                diff_coeff = max(dot(L, N), 0.0)
                H = normalize(L + normalize(-v[SOneTo(3)]))
                spec_coeff = max(dot(H, N), 0.0)^shininess
                c = RGBA(c)
                new_c = (ambient .+ diff_coeff .* diffuse) .* Vec3f0(c.r, c.g, c.b) .+
                        specular * spec_coeff
                RGBA(new_c..., c.alpha)
            end
        else
            cols[k]
        end
        # debug normal coloring
        # n1, n2, n3 = Vec3f0(0.5) .+ 0.5ns[f]
        # c1 = RGB(n1...)
        # c2 = RGB(n2...)
        # c3 = RGB(n3...)

        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1[1], t1[2])
        Cairo.mesh_pattern_line_to(pattern, t2[1], t2[2])
        Cairo.mesh_pattern_line_to(pattern, t3[1], t3[2])

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
    end
    Cairo.set_source(ctx, pattern)
    Cairo.close_path(ctx)
    Cairo.paint(ctx)
    return nothing
end


################################################################################
#                                   Surface                                    #
################################################################################


function draw_atomic(scene::Scene, screen::CairoScreen, primitive::AbstractPlotting.Surface)
    # Pretend the surface plot is a mesh plot and plot that instead
    mesh = surface2mesh(primitive[1][], primitive[2][], primitive[3][])
    primitive[:color][] = primitive[3][][:]
    if !haskey(primitive, :faceculling)
        primitive[:faceculling] = Node(-0.1)
    end
    draw_mesh3D(scene, screen, primitive, mesh=mesh)
    return nothing
end

function surface2mesh(xs::AbstractVector, ys::AbstractVector, zs::AbstractMatrix)
    ps = [Point3f0(xs[i], ys[j], zs[i, j]) for j in eachindex(ys) for i in eachindex(xs)]
    idxs = LinearIndices(size(zs))
    faces = [
        QuadFace(idxs[i, j], idxs[i+1, j], idxs[i+1, j+1], idxs[i, j+1])
        for j in 1:size(zs, 2)-1 for i in 1:size(zs, 1)-1
    ]
    normal_mesh(ps, faces)
end

function surface2mesh(xs::AbstractMatrix, ys::AbstractMatrix, zs::AbstractMatrix)
    ps = [Point3f0(xs[i, j], ys[i, j], zs[i, j]) for j in 1:size(zs, 2) for i in 1:size(zs, 1)]
    idxs = LinearIndices(size(zs))
    faces = [
        QuadFace(idxs[i, j], idxs[i+1, j], idxs[i+1, j+1], idxs[i, j+1])
        for j in 1:size(zs, 2)-1 for i in 1:size(zs, 1)-1
    ]
    normal_mesh(ps, faces)
end

################################################################################
#                                 MeshScatter                                  #
################################################################################


function draw_atomic(scene::Scene, screen::CairoScreen, primitive::AbstractPlotting.MeshScatter)
    @get_attribute(primitive, (color, model, marker, markersize, rotations))

    if color isa AbstractArray{<: Number}
        color = numbers_to_colors(color, primitive)
    end

    m = normal_mesh(marker)
    pos = primitive[1][]
    # For correct z-ordering we need to be in view/camera or screen space
    model = copy(model)
    view = scene.camera.view[]

    zorder = sortperm(pos, by = p -> begin
        p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, p, 0f0), 1f0)
        cam_pos = view * model * p4d
        cam_pos[3] / cam_pos[4]
    end, rev=false)

    submesh = Attributes(
        model=model,
        color=color,
        shading=primitive.shading, lightposition=primitive.lightposition,
        ambient=primitive.ambient, diffuse=primitive.diffuse,
        specular=primitive.specular, shininess=primitive.shininess,
        faceculling=get(primitive, :faceculling, -0.1)
    )

    if !(rotations isa Vector)
        R = AbstractPlotting.rotationmatrix4(to_rotation(rotations))
        submesh[:model] = model * R
    end
    scales = primitive[:markersize][]

    for i in zorder
        p = pos[i]
        if color isa AbstractVector
            submesh[:color] = color[i]
        end
        if rotations isa Vector
            R = AbstractPlotting.rotationmatrix4(to_rotation(rotations[i]))
            submesh[:model] = model * R
        end
        scale = markersize isa Vector ? markersize[i] : markersize

        draw_mesh3D(
            scene, screen, submesh, mesh = m, pos = p,
            scale = scale isa Real ? Vec3f0(scale) : to_ndim(Vec3f0, scale, 1f0)
        )
    end

    return nothing
end
