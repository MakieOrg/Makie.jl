# TODO: refactor

# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!

arrow_head(N, marker, quality) = marker
function arrow_head(N, marker::Automatic, quality)
    if N == 2
        return :utriangle
    else
        merge([
           _circle(Point3f(0), 0.5f0, Vec3f(0,0,-1), quality),
           _mantle(Point3f(0), Point3f(0,0,1), 0.5f0, 0f0, quality)
        ])
    end
end

arrow_tail(N, marker, quality) = marker
function arrow_tail(N, marker::Automatic, quality)
    if N == 2
        nothing
    else
        merge([
            _circle(Point3f(0,0,-1), 0.5f0, Vec3f(0,0,-1), quality),
            _mantle(Point3f(0,0,-1), Point3f(0), 0.5f0, 0.5f0, quality)
        ])
    end
end


function _mantle(origin, extremity, r1, r2, N)
    dphi = 2pi / N

    # Equivalent to
    # xy = cos(atan(temp))
    # z  = sin(atan(temp))
    temp = -(r2-r1) / norm(extremity .- origin)
    xy = 1.0 / sqrt(temp^2 + 1)
    z = temp / sqrt(temp^2 + 1)

    coords = Vector{Point3f}(undef, 2N)
    normals = Vector{Vec3f}(undef, 2N)
    faces = Vector{GLTriangleFace}(undef, 2N)

    for (i, phi) in enumerate(0:dphi:2pi-0.5dphi)
        coords[2i - 1] = origin .+ r1 * Vec3f(cos(phi), sin(phi), 0)
        coords[2i] = extremity .+ r2 * Vec3f(cos(phi), sin(phi), 0)
        normals[2i - 1] = Vec3f(xy*cos(phi), xy*sin(phi), z)
        normals[2i] = Vec3f(xy*cos(phi), xy*sin(phi), z)
        faces[2i - 1] = GLTriangleFace(2i-1, mod1(2i+1, 2N), 2i)
        faces[2i] = GLTriangleFace(mod1(2i+1, 2N), mod1(2i+2, 2N), 2i)
    end

    GeometryBasics.mesh(coords, faces; normal = normals)
end

# GeometryBasics.Circle doesn't work with Point3f...
function _circle(origin, r, normal, N)
    dphi = 2pi / N

    coords = Vector{Point3f}(undef, N+1)
    normals = fill(normal, N+1)
    faces = Vector{GLTriangleFace}(undef, N)

    for (i, phi) in enumerate(0:dphi:2pi-0.5dphi)
        coords[i] = origin .+ r * Vec3f(cos(phi), sin(phi), 0)
        faces[i] = GLTriangleFace(N+1, mod1(i+1, N), i)
    end
    coords[N+1] = origin

    GeometryBasics.mesh(coords, faces; normal = normals)
end

# vec(::Point) and vec(::Vec) works (returns input), but vec(::Tuple) errors
convert_arguments(::Type{<: Arrows}, pos::VecTypes{N}, dir::VecTypes{N}) where {N} = ([pos], [dir])

function convert_arguments(::Type{<: Arrows}, pos, dir)
    return (
        convert_arguments(PointBased(), vec(pos))[1],
        convert_arguments(PointBased(), vec(dir))[1]
    )
end
function convert_arguments(::Type{<: Arrows}, x, y, u, v)
    return (
        convert_arguments(PointBased(), vec(x), vec(y))[1],
        convert_arguments(PointBased(), vec(u), vec(v))[1]
    )
end
function convert_arguments(::Type{<: Arrows}, x, y, z, u, v, w)
    return (
        convert_arguments(PointBased(), vec(x), vec(y), vec(z))[1],
        convert_arguments(PointBased(), vec(u), vec(v), vec(w))[1]
    )
end



function plot!(arrowplot::Arrows{<: Tuple{AbstractVector{<: VecTypes{N}}, V}}) where {N, V}
    @extract arrowplot (
        points, directions, colormap, colorscale, normalize, align,
        arrowtail, color, linecolor, linestyle, linewidth, lengthscale,
        arrowhead, arrowsize, arrowcolor, quality, transform_marker,
        # passthrough
        diffuse, specular, shininess, shading,
        fxaa, ssao, transparency, visible, inspectable
    )

    line_c = lift((a, c)-> a === automatic ? c : a , arrowplot, linecolor, color)
    arrow_c = lift((a, c)-> a === automatic ? c : a , arrowplot, arrowcolor, color)
    fxaa_bool = lift(fxaa -> fxaa == automatic ? N == 3 : fxaa, arrowplot, fxaa) # automatic -> true for 3D, false for 2D
    tm = lift(tm -> tm == automatic ? N == 3 : tm, arrowplot, transform_marker) # automatic -> true for 3D, false for 2D

    marker_head = lift((ah, q) -> arrow_head(N, ah, q), arrowplot, arrowhead, quality)
    if N == 2
        headstart = lift(arrowplot, points, directions, normalize, align, lengthscale) do points, dirs, n, align, s
            map(points, dirs) do p1, dir
                dir = n ? LinearAlgebra.normalize(dir) : dir
                if align in (:head, :lineend, :tailend, :headstart, :center)
                    shift = s .* dir
                else
                    shift = Vec2f(0)
                end
                return Point2f(p1 .- shift) => Point2f(p1 .- shift .+ (dir .* s))
            end
        end

        scene = parent_scene(arrowplot)
        rotations = directions

        # for 2D arrows, compute the correct marker rotation given the projection / scene size
        # for the screen-space marker
        if is_pixel_space(arrowplot.markerspace[])
            rotations = lift(arrowplot, scene.camera.projectionview, scene.viewport, headstart) do pv, pxa, hs
                angles = map(hs) do (start, stop)
                    pstart = project(scene, start)
                    pstop = project(scene, stop)
                    diff = pstop - pstart
                    n = norm(diff)
                    if n == 0
                        zero(n)
                    else
                        angle = acos(diff[2] / norm(diff))
                        angle = ifelse(diff[1] > 0, 2pi - angle, angle)
                    end
                end
                Billboard(angles)
            end
        end

        linesegments!(
            arrowplot, headstart,
                      color=line_c, colormap=colormap, colorscale=colorscale, linestyle=linestyle,
                      colorrange=arrowplot.colorrange,
            linewidth=lift(lw -> lw === automatic ? 1.0f0 : lw, arrowplot, linewidth),
            fxaa = fxaa_bool, inspectable = inspectable,
            transparency = transparency, visible = visible,
        )
        scatter!(
            arrowplot,
            lift(x-> last.(x), arrowplot, headstart),
            marker=marker_head,
            markersize = lift(as-> as === automatic ? theme(scene, :markersize)[] : as, arrowplot, arrowsize),
            color = arrow_c, rotation = rotations, strokewidth = 0.0,
                 colormap=colormap, markerspace=arrowplot.markerspace, colorrange=arrowplot.colorrange,
            fxaa = fxaa_bool, inspectable = inspectable,
            transparency = transparency, visible = visible,
            transform_marker = tm
        )
    else
        msize = Observable{Union{Vec3f, Vector{Vec3f}}}()
        markersize = Observable{Union{Vec3f, Vector{Vec3f}}}()
        lift!(arrowplot, msize, directions, normalize, linewidth, lengthscale, arrowsize) do dirs, n, linewidth, ls, as
            ms = as isa Automatic ? Vec3f(0.2, 0.2, 0.3) : as
            markersize[] = to_3d_scale(ms)
            lw = linewidth isa Automatic ? minimum(ms) * 0.5 : linewidth
            if n
                return broadcast((lw, ls) -> Vec3f(lw, lw, ls), lw, ls)
            else
                return broadcast(lw, dirs, ls) do lw, dir, s
                    return Vec3f(lw, lw, norm(dir) * s)
                end
            end
        end

        start = lift(arrowplot, points, directions, align, lengthscale) do points, dirs, align, scales
            return broadcast(points, dirs, scales) do p, dir, s
                if align in (:head, :lineend, :tailend, :headstart, :center)
                    shift = Vec3f(0)
                else
                    shift = -s .* dir
                end
                return Point3f(p .- shift)
            end
        end
        marker_tail = lift((at, q) -> arrow_tail(3, at, q), arrowplot, arrowtail, quality)
        meshscatter!(
            arrowplot,
            start, rotation = directions, markersize = msize,
            marker = marker_tail,
            color = line_c, colormap = colormap, colorscale = colorscale, colorrange = arrowplot.colorrange,
            fxaa = fxaa_bool, ssao = ssao, shading = shading,
            diffuse = diffuse, specular = specular, shininess = shininess,
            inspectable = inspectable, transparency = transparency, visible = visible,
            transform_marker = tm
        )
        meshscatter!(
            arrowplot,
            start, rotation = directions, markersize = markersize,
            marker = marker_head,
            color = arrow_c, colormap = colormap, colorscale = colorscale, colorrange = arrowplot.colorrange,
            fxaa = fxaa_bool, ssao = ssao, shading = shading,
            diffuse = diffuse, specular = specular, shininess = shininess,
            inspectable = inspectable, transparency = transparency, visible = visible,
            transform_marker = tm
        )
    end

end

################################################################################


"""
    arrows(points, directions; kwargs...)
    arrows(x, y, u, v)
    arrows(x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    arrows(x, y, z, u, v, w)
    arrows(x, y, [z], f::Function)

Plots arrows at the specified points with the specified components.
`u` and `v` are interpreted as vector components (`u` being the x
and `v` being the y), and the vectors are plotted with the tails at
`x`, `y`.

If `x, y, u, v` are `<: AbstractVector`, then each 'row' is plotted
as a single vector.

If `u, v` are `<: AbstractMatrix`, then `x` and `y` are interpreted as
specifications for a grid, and `u, v` are plotted as arrows along the
grid.

`arrows` can also work in three dimensions.

If a `Function` is provided in place of `u, v, [w]`, then it must accept
a `Point` as input, and return an appropriately dimensioned `Point`, `Vec`,
or other array-like output.
"""
@recipe Arrows2D (points, directions) begin
    "Sets the shape of the arrow tail in units relative to the tailwidth and taillength."
    tail = Rect2f(0,0,1,1) # TODO: placeholder
    "Sets the shape of the arrow shaft in units relative to the shaftwidth and shaftlength."
    shaft = Rect2f(0,0,1,1)
    "Sets the shape of the arrow tip in units relative to the tipwidth and tiplength."
    tip = Point2f[(0, 0), (1, 0.5), (0, 1)]

    """
    Sets the width of the arrow tail. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tailwidth = 14
    """
    Sets the length of the arrow tail. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tail being drawn.
    """
    taillength = 0
    """
    Sets the width of the arrow shaft. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    shaftwidth = 3
    """
    Sets the length of the arrow shaft. When set to `automatic` the length of the shaft will be
    derived from the length of the arrow, the `taillength` and the `tiplength`. If the result falls
    below `minshaftlength`, that value is used instead and all lengths and widths are scaled to fit.
    If the `shaftlength` is set to a value, the lengths and widths of the arrow are always scaled.
    """
    shaftlength = automatic
    "Sets the minimum shaft length, see `shaftlength`."
    minshaftlength = 10
    """
    Sets the width of the arrow tip. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tipwidth = 14
    """
    Sets the length of the arrow tip. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tip being drawn.
    """
    tiplength = 8

    "Sets the color of the arrow. Can be overridden separately using `tailcolor`, `shaftcolor` and `tipcolor`."
    color = :black
    "Sets the color of the arrow tail. Defaults to `color`"
    tailcolor = automatic
    "Sets the color of the arrow shaft. Defaults to `color`"
    shaftcolor = automatic
    "Sets the color of the arrow tip. Defaults to `color`"
    tipcolor = automatic

    """
    Sets the alignment of the arrow, i.e. which part of the arrow is placed at the given positions.
    - `align = :tail` or `align = 0` places the arrow tail at the given position. This makes the arrow point away from that position.
    - `align = :center` or `align = 0.5` places the arrow center (based on its total length) at the given position
    - `align = :tip` or `align = 1.0` places the tip of the arrow at the given position. This makes the arrow point to that position.

    Values outside of (0, 1) can also be used to create gaps between the arrow and its anchor position.
    """
    align = :tail
    """
    Scales the length of the arrow (as calculated from directions) by some factor.
    """
    lengthscale = 1f0
    """
    By default each arrow length is derived as the norm (length) of the corresponding direction.
    Setting `normalize = true` disables this, so that each arrow has the same length. The arrow
    metrics follow directly from tail/shaft/tip- length/width (and minshaftlength if shaftlength
    is automatic).
    """
    normalize = false

    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
end

convert_arguments(::Type{<: Arrows2D}, args...) = convert_arguments(Arrows, args...)


function _aligned_arrow_points(points::Vector{<: VecTypes{N}}, directions::Vector{<: VecTypes{N}}, align, normalize)
    if align === :tail
        align_val = 0.0
    elseif align === :center
        align_val = 0.5
    elseif align === :tip
        align_val = 1.0
    else
        align_val = Float64(align)
    end

    output = similar(points, 2 * length(points))
    for i in eachindex(points)
        dir = normalize ? directions[i] : normalize(directions[i])
        # startpoint, endpoint
        output[2*i-1] = points[i] - align_val * dir
        output[2*i] = points[i] + (1 - align_val) * dir
    end
    return output
end

function _get_arrow_shape(x, len, width, shaftwidth, color)
    if len == 0 || width == 0
        return GeometryBasics.Mesh(Point2f[], GLTriangleFace[], color = RGBAf[])
    else
        m = _get_arrow_shape(x, len, width, shaftwidth)
        cs = fill(color, length(coordinates(m)))
        for i in eachindex(m.position)
            m.position[i] -= Vec2f(0, 0.5 * width) # center width
        end
        return GeometryBasics.mesh(m, color = cs)
    end
end

_get_arrow_shape(f::Function, length, width, shaftwidth) = poly_convert(f(length, width, shaftwidth))
function _get_arrow_shape(polylike, length, width, shaftwidth)
    # deepcopy so each each meshes positions are independent
    mesh = deepcopy(poly_convert(polylike))
    for i in eachindex(mesh.position)
        mesh.position[i] = (length, width) .* mesh.position[i] # scale
    end
    return mesh
end

function _apply_arrow_transform!(m::GeometryBasics.Mesh, R::Mat2, origin, offset)
    for i in eachindex(m.position)
        m.position[i] = origin + R * (m.position[i] .+ (offset, 0))
    end
    return
end

function plot!(plot::Arrows2D)
    @extract plot (
        points, directions,
        colormap, colorscale, normalize, align, lengthscale,
        tail, taillength, tailwidth,
        shaft, shaftlength, minshaftlength, shaftwidth,
        tip, tiplength, tipwidth,
        transparency, visible, inspectable
    )

    tailcolor = map(default_automatic, plot, plot.tailcolor, plot.color)
    shaftcolor = map(default_automatic, plot, plot.shaftcolor, plot.color)
    tipcolor = map(default_automatic, plot, plot.tipcolor, plot.color)

    # TODO: Think about normalize

    arrowpoints = map(_aligned_arrow_points, plot, points, directions, align, normalize)

    scene = parent_scene(plot)
    arrowpoints_px = map(plot,
            arrowpoints, transform_func_obs(plot), plot.model, plot.space, scene.camera.projectionview, scene.viewport
        ) do ps, tf, model, space, pv, vp
        return plot_to_screen(plot, ps)
    end

    arrow_metrics = map(
        plot, arrowpoints_px, normalize, lengthscale,
        taillength, tailwidth,
        shaftlength, minshaftlength, shaftwidth,
        tiplength, tipwidth,
    ) do points, normalize, lengthscale, taillength, tailwidth,
        shaftlength, minshaftlength, shaftwidth,
        tiplength, tipwidth

        metrics = Vector{NTuple{6, Float64}}(undef, div(length(points), 2))
        for i in eachindex(metrics)
            target_length = lengthscale * norm(points[2i] - points[2i-1])
            target_shaftlength = if shaftlength === automatic
                max(minshaftlength, target_length - taillength - tiplength)
            else
                shaftlength
            end
            arrow_length = target_shaftlength + taillength + tiplength
            arrow_scaling = target_length / arrow_length
            metrics[i] = arrow_scaling .* (taillength, tailwidth, target_shaftlength, shaftwidth, tiplength, tipwidth)
        end

        return metrics
    end

    # skip arrow_metrics input to avoid double update (let arrow metrics trigger)
    merged_mesh = map(plot,
            arrow_metrics, tail, shaft, tip, tailcolor, shaftcolor, tipcolor
        ) do metrics, tail, shaft, tip, tailcolor, shaftcolor, tipcolor

        arrow_points = arrowpoints_px[]
        tailc = to_color(tailcolor)
        shaftc = to_color(shaftcolor)
        tipc = to_color(tipcolor)
        merged_mesh = GeometryBasics.Mesh(Point2f[], GLTriangleFace[], color = RGBAf[])

        meshes = [merged_mesh, merged_mesh, merged_mesh, merged_mesh]

        for i in eachindex(metrics)
            # scale and add color
            taillength, tailwidth, shaftlength, shaftwidth, tiplength, tipwidth = metrics[i]
            tail_m  = _get_arrow_shape(tail,  taillength,  tailwidth,  shaftwidth, tailc)
            shaft_m = _get_arrow_shape(shaft, shaftlength, shaftwidth, shaftwidth, shaftc)
            tip_m   = _get_arrow_shape(tip,   tiplength,   tipwidth,   shaftwidth, tipc)

            # rotate + translate
            startpoint = arrow_points[2i-1]
            endpoint = arrow_points[2i]
            direction = endpoint - startpoint
            angle = atan(direction[2], direction[1])
            R = rotmatrix2d(angle)

            _apply_arrow_transform!(tail_m, R, startpoint, 0.0)
            _apply_arrow_transform!(shaft_m, R, startpoint, taillength)
            _apply_arrow_transform!(tip_m, R, startpoint, taillength + shaftlength)

            meshes[1] = merged_mesh
            meshes[2] = tail_m
            meshes[3] = shaft_m
            meshes[4] = tip_m

            merged_mesh = merge(meshes)
        end

        return merged_mesh
    end

    mesh!(plot, merged_mesh, space = :pixel)

end

data_limits(p::Arrows2D) = update_boundingbox(Rect3d(p[1][]), Rect3d(p[1][] .+ p[2][]))
boundingbox(p::Arrows2D, space::Symbol) = apply_transform_and_model(p, data_limits(p))