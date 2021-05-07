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
@recipe(Arrows, points, directions) do scene
    theme = merge!(
        default_theme(scene),
        Attributes(
            arrowhead = automatic,
            arrowtail = automatic,
            color = :black,
            linecolor = automatic,
            arrowsize = automatic,
            linestyle = nothing,
            align = :origin,
            normalize = false,
            lengthscale = 1f0,
            colormap = :viridis,
            quality = 32,
        )
    )
    theme[:fxaa] = automatic
    theme[:linewidth] = automatic
    # connect arrow + linecolor by default
    get!(theme, :arrowcolor, theme[:linecolor])
    theme
end

# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!

arrow_head(N, marker, quality) = marker
function arrow_head(N, marker::Automatic, quality)
    if N == 2
        return '▲'
    else
        merge([
           _circle(Point3f0(0), 0.5f0, Vec3f0(0,0,-1), quality),
           _mantle(Point3f0(0), Point3f0(0,0,1), 0.5f0, 0f0, quality)
        ])
    end
end

arrow_tail(N, marker, quality) = marker
function arrow_tail(N, marker::Automatic, quality)
    if N == 2
        nothing
    else
        merge([
            _circle(Point3f0(0,0,-1), 0.5f0, Vec3f0(0,0,-1), quality),
            _mantle(Point3f0(0,0,-1), Point3f0(0), 0.5f0, 0.5f0, quality)
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

    coords = Vector{Point3f0}(undef, 2N)
    normals = Vector{Vec3f0}(undef, 2N)
    faces = Vector{GLTriangleFace}(undef, 2N)

    for (i, phi) in enumerate(0:dphi:2pi-0.5dphi)
        coords[2i - 1] = origin .+ r1 * Vec3f0(cos(phi), sin(phi), 0)
        coords[2i] = extremity .+ r2 * Vec3f0(cos(phi), sin(phi), 0)
        normals[2i - 1] = Vec3f0(xy*cos(phi), xy*sin(phi), z)
        normals[2i] = Vec3f0(xy*cos(phi), xy*sin(phi), z)
        faces[2i - 1] = GLTriangleFace(2i-1, mod1(2i+1, 2N), 2i)
        faces[2i] = GLTriangleFace(mod1(2i+1, 2N), mod1(2i+2, 2N), 2i)
    end

    GeometryBasics.Mesh(meta(coords; normals=normals), faces)
end

# GeometryBasics.Circle doesn't work with Point3f0...
function _circle(origin, r, normal, N)
    dphi = 2pi / N

    coords = Vector{Point3f0}(undef, N+1)
    normals = fill(normal, N+1)
    faces = Vector{GLTriangleFace}(undef, N)

    for (i, phi) in enumerate(0:dphi:2pi-0.5dphi)
        coords[i] = origin .+ r * Vec3f0(cos(phi), sin(phi), 0)
        faces[i] = GLTriangleFace(N+1, mod1(i+1, N), i)
    end
    coords[N+1] = origin

    GeometryBasics.Mesh(meta(coords; normals=normals), faces)
end


convert_arguments(::Type{<: Arrows}, x, y, u, v) = (Point2f0.(x, y), Vec2f0.(u, v))
function convert_arguments(::Type{<: Arrows}, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    (vec(Point2f0.(x, y')), vec(Vec2f0.(u, v)))
end
convert_arguments(::Type{<: Arrows}, x, y, z, u, v, w) = (Point3f0.(x, y, z), Vec3f0.(u, v, w))

function plot!(arrowplot::Arrows{<: Tuple{AbstractVector{<: Point{N, T}}, V}}) where {N, T, V}
    @extract arrowplot (
        points, directions, colormap, normalize, align,
        arrowtail, color, linecolor, linestyle, linewidth, lengthscale,
        arrowhead, arrowsize, arrowcolor, quality,
        # passthrough
        lightposition, ambient, diffuse, specular, shininess,
        fxaa, ssao, transparency, visible
    )

    arrow_c = map((a, c)-> a === automatic ? c : a , arrowcolor, color)
    line_c = map((a, c)-> a === automatic ? c : a , linecolor, color)

    fxaa_bool = @lift($fxaa == automatic ? false : $fxaa)
    if N == 2
        headstart = lift(points, directions, normalize, align, lengthscale) do points, dirs, n, align, s
            map(points, dirs) do p1, dir
                dir = n ? StaticArrays.normalize(dir) : dir
                if align in (:head, :lineend, :tailend, :headstart, :center)
                    shift = s .* dir
                else
                    shift = Vec2f0(0)
                end
                Point2f0(p1 .- shift) => Point2f0(p1 .- shift .+ (dir .* s))
            end
        end

        linesegments!(
            arrowplot, headstart,
            color = line_c, colormap = colormap, linestyle = linestyle,
            linewidth = @lift($linewidth === automatic ? 1f0 : $linewidth),
            fxaa = fxaa_bool,
            transparency = transparency, visible = visible
        )
        scatter!(
            arrowplot,
            lift(x-> last.(x), headstart),
            marker = @lift(arrow_head(2, $arrowhead, $quality)),
            markersize = @lift($arrowsize === automatic ? 0.3 : $arrowsize),
            color = arrow_c, rotations = directions, strokewidth = 0.0,
            colormap = colormap,
            fxaa = fxaa_bool,
            transparency = transparency, visible = visible
        )
    else
        start = lift(points, directions, align, lengthscale) do points, dirs, align, s
            map(points, dirs) do p, dir
                if align in (:head, :lineend, :tailend, :headstart, :center)
                    shift = Vec3f0(0)
                else
                    shift = -s .* dir
                end
                Point3f0(p .- shift)
            end
        end
        meshscatter!(
            arrowplot,
            start, rotations = directions,
            marker = @lift(arrow_tail(3, $arrowhead, $quality)),
            markersize = lift(directions, normalize, linewidth, lengthscale) do dirs, n, linewidth, ls
                lw = linewidth === automatic ? 0.05f0 : linewidth
                if n
                    Vec3f0(lw, lw, ls)
                else
                    map(dir -> Vec3f0(lw, lw, norm(dir) * ls), dirs)
                end
            end,
            color = line_c, colormap = colormap,
            fxaa = fxaa_bool, ssao = ssao,
            lightposition = lightposition, ambient = ambient, diffuse = diffuse,
            specular = specular, shininess = shininess,
            transparency = transparency, visible = visible
        )
        meshscatter!(
            arrowplot,
            start, rotations = directions,
            marker = @lift(arrow_head(3, $arrowhead, $quality)),
            markersize = lift(arrowsize, typ=Any) do as
                as === automatic ? Vec3f0(0.2, 0.2, 0.3) : as
            end,
            color = arrow_c, colormap = colormap,
            fxaa = fxaa_bool, ssao = ssao,
            lightposition = lightposition, ambient = ambient, diffuse = diffuse,
            specular = specular, shininess = shininess,
            transparency = transparency, visible = visible
        )
    end
end
