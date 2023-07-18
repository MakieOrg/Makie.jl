"""
    arrows(points, directions; kwargs...)
    arrows(x, y, u, v)
    arrows(x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    arrows(x, y, z, u, v, w)

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

## Attributes
$(ATTRIBUTES)
"""
arrows

"""
See [`arrows`](@ref).
"""
arrows!

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

    GeometryBasics.Mesh(meta(coords; normals=normals), faces)
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

    GeometryBasics.Mesh(meta(coords; normals=normals), faces)
end


convert_arguments(::Type{<: Arrows}, x, y, u, v) = (Point2f.(x, y), Vec2f.(u, v))
function convert_arguments(::Type{<: Arrows}, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    (vec(Point2f.(x, y')), vec(Vec2f.(u, v)))
end
convert_arguments(::Type{<: Arrows}, x, y, z, u, v, w) = (Point3f.(x, y, z), Vec3f.(u, v, w))

function plot!(arrowplot::Arrows{<: Tuple{AbstractVector{<: Point{N}}, V}}) where {N, V}
    @extract arrowplot (
        points, directions, colormap, normalize, align,
        arrowtail, color, linecolor, linestyle, linewidth, lengthscale,
        arrowhead, arrowsize, arrowcolor, quality,
        # passthrough
        diffuse, specular, shininess,
        fxaa, ssao, transparency, visible, inspectable
    )

    arrow_c = map((a, c)-> a === automatic ? c : a , arrowplot, arrowcolor, color)
    line_c = map((a, c)-> a === automatic ? c : a , arrowplot, linecolor, color)
    fxaa_bool = lift(fxaa -> fxaa == automatic ? N == 3 : fxaa, arrowplot, fxaa) # automatic == fxaa for 3D

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
            rotations = lift(arrowplot, scene.camera.projectionview, scene.px_area, headstart) do pv, pxa, hs
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
            color = line_c, colormap = colormap, linestyle = linestyle,
            linewidth=lift(lw -> lw === automatic ? 1.0f0 : lw, arrowplot, linewidth),
            fxaa = fxaa_bool, inspectable = inspectable,
            transparency = transparency, visible = visible,
        )
        scatter!(
            arrowplot,
            lift(x-> last.(x), arrowplot, headstart),
            marker=marker_head,
            markersize = lift(as-> as === automatic ? theme(scene, :markersize)[] : as, arrowplot, arrowsize),
            color = arrow_c, rotations = rotations, strokewidth = 0.0,
            colormap = colormap, markerspace = arrowplot.markerspace,
            fxaa = fxaa_bool, inspectable = inspectable,
            transparency = transparency, visible = visible
        )
    else
        msize = Observable{Union{Vec3f, Vector{Vec3f}}}()
        markersize = Observable{Union{Vec3f, Vector{Vec3f}}}()
        map!(arrowplot, msize, directions, normalize, linewidth, lengthscale, arrowsize) do dirs, n, linewidth, ls, as
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
            start, rotations = directions,
            marker=marker_tail,
            markersize = msize,
            color = line_c, colormap = colormap,
            fxaa = fxaa_bool, ssao = ssao,
            diffuse = diffuse,
            specular = specular, shininess = shininess, inspectable = inspectable,
            transparency = transparency, visible = visible
        )
        meshscatter!(
            arrowplot,
            start, rotations = directions,
            marker=marker_head,
            markersize = markersize,
            color = arrow_c, colormap = colormap,
            fxaa = fxaa_bool, ssao = ssao,
            diffuse = diffuse,
            specular = specular, shininess = shininess, inspectable = inspectable,
            transparency = transparency, visible = visible
        )
    end

end
