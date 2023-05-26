struct DelaunayTriangulation end

"""
    tricontourf(xs, ys, zs; kwargs...)

Plots a filled tricontour of the height information in `zs` at horizontal positions `xs`
and vertical positions `ys`.

## Attributes

### Specific to `Tricontourf`

- `levels = 10` can be either an `Int` which results in n bands delimited by n+1 equally spaced levels, or it can be an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 bands.
- `mode = :normal` sets the way in which a vector of levels is interpreted, if it's set to `:relative`, each number is interpreted as a fraction between the minimum and maximum values of `zs`. For example, `levels = 0.1:0.1:1.0` would exclude the lower 10% of data.
- `extendlow = nothing`. This sets the color of an optional additional band from `minimum(zs)` to the lowest value in `levels`. If it's `:auto`, the lower end of the colormap is picked and the remaining colors are shifted accordingly. If it's any color representation, this color is used. If it's `nothing`, no band is added.
- `extendhigh = nothing`. This sets the color of an optional additional band from the highest value of `levels` to `maximum(zs)`. If it's `:auto`, the high end of the colormap is picked and the remaining colors are shifted accordingly. If it's any color representation, this color is used. If it's `nothing`, no band is added.
- `triangulation = DelaunayTriangulation()`. The mode with which the points in `xs` and `ys` are triangulated. Passing `DelaunayTriangulation()` performs a delaunay triangulation. You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}` with size (3, n), where each column specifies the vertex indices of one triangle.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color` sets the color of the plot. It can be given as a named color `Symbol` or a `Colors.Colorant`. Transparency can be included either directly as an alpha value in the `Colorant` or as an additional float in a tuple `(color, alpha)`. The color can also be set for each scattered marker by passing a `Vector` of colors or be used to index the `colormap` by passing a `Real` number or `Vector{<: Real}`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap from which the band colors are sampled.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Tricontourf) do scene
    Theme(
        levels = 10,
        mode = :normal,
        colormap = theme(scene, :colormap),
        extendlow = nothing,
        extendhigh = nothing,
        nan_color = :transparent,
        inspectable = theme(scene, :inspectable),
        transparency = false,
        triangulation = DelaunayTriangulation()
    )
end

function Makie.convert_arguments(::Type{<:Tricontourf}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::AbstractVector{<:Real})
    map(x -> elconvert(Float32, x), (x, y, z))
end

function compute_contourf_colormap(levels, cmap, elow, ehigh)
    levels_scaled = (levels .- minimum(levels)) ./ (maximum(levels) - minimum(levels))
    n = length(levels_scaled)

    _cmap = to_colormap(cmap)

    if elow === :auto && ehigh !== :auto
        cm_base = cgrad(_cmap, n + 1; categorical=true)[2:end]
        cm = cgrad(cm_base, levels_scaled; categorical=true)
    elseif ehigh === :auto && elow !== :auto
        cm_base = cgrad(_cmap, n + 1; categorical=true)[1:(end - 1)]
        cm = cgrad(cm_base, levels_scaled; categorical=true)
    elseif ehigh === :auto && elow === :auto
        cm_base = cgrad(_cmap, n + 2; categorical=true)[2:(end - 1)]
        cm = cgrad(cm_base, levels_scaled; categorical=true)
    else
        cm = cgrad(_cmap, levels_scaled; categorical=true)
    end
    return cm
end

function compute_lowcolor(el, cmap)
    if isnothing(el)
        return RGBAf(0, 0, 0, 0)
    elseif el === automatic || el === :auto
        return RGBAf(to_colormap(cmap)[begin])
    else
        return to_color(el)::RGBAf
    end
end

function compute_highcolor(eh, cmap)
    if isnothing(eh)
        return RGBAf(0, 0, 0, 0)
    elseif eh === automatic || eh === :auto
        return RGBAf(to_colormap(cmap)[end])
    else
        return to_color(eh)::RGBAf
    end
end

function Makie.plot!(c::Tricontourf{<:Tuple{<:AbstractVector{<:Real},<:AbstractVector{<:Real},<:AbstractVector{<:Real}}})
    xs, ys, zs = c[1:3]

    c.attributes[:_computed_levels] = lift(c, zs, c.levels, c.mode) do zs, levels, mode
        return _get_isoband_levels(Val(mode), levels, vec(zs))
    end

    colorrange = lift(extrema_nan, c, c._computed_levels)
    computed_colormap = lift(compute_contourf_colormap, c, c._computed_levels, c.colormap, c.extendlow,
                             c.extendhigh)
    c.attributes[:_computed_colormap] = computed_colormap

    lowcolor = Observable{RGBAf}()
    map!(compute_lowcolor, lowcolor, c.extendlow, c.colormap)
    c.attributes[:_computed_extendlow] = lowcolor
    is_extended_low = lift(!isnothing, c, c.extendlow)

    highcolor = Observable{RGBAf}()
    map!(compute_highcolor, highcolor, c.extendhigh, c.colormap)
    c.attributes[:_computed_extendhigh] = highcolor
    is_extended_high = lift(!isnothing, c, c.extendhigh)

    PolyType = typeof(Polygon(Point2f[], [Point2f[]]))

    polys = Observable(PolyType[])
    colors = Observable(Float64[])

    function calculate_polys(xs, ys, zs, levels::Vector{Float32}, is_extended_low, is_extended_high, triangulation)
        empty!(polys[])
        empty!(colors[])

        N = mapreduce(length, min, (xs, ys, zs))
        xview = view(xs, 1:N)
        yview = view(ys, 1:N)
        zview = view(zs, 1:N)

        levels = copy(levels)
        # adjust outer levels to be inclusive
        levels[1] = prevfloat(levels[1])
        levels[end] = nextfloat(levels[end])
        @assert issorted(levels)
        is_extended_low && pushfirst!(levels, -Inf)
        is_extended_high && push!(levels, Inf)
        lows = levels[1:end-1]
        highs = levels[2:end]

        trianglelist = compute_triangulation(triangulation, xview, yview)
        filledcontours = filled_tricontours(xview, yview, zview, trianglelist, levels)

        levelcenters = (highs .+ lows) ./ 2

        for (fc, lc) in zip(filledcontours, levelcenters)
            pointvecs = map(fc.polylines) do vecs
                map(Point2f, vecs)
            end
            if isempty(pointvecs)
                continue
            end

            for pointvec in pointvecs
                p = Makie.Polygon(pointvec)
                push!(polys[], p)
                push!(colors[], lc)
            end
        end
        notify(polys)
        return
    end

    onany(calculate_polys, c, xs, ys, zs, c._computed_levels, is_extended_low, is_extended_high, c.triangulation)
    # onany doesn't get called without a push, so we call
    # it on a first run!
    calculate_polys(xs[], ys[], zs[], c._computed_levels[], is_extended_low[], is_extended_high[], c.triangulation[])

    poly!(c,
        polys,
        colormap = c._computed_colormap,
        colorrange = colorrange,
        highclip = highcolor,
        lowclip = lowcolor,
        nan_color = c.nan_color,
        color = colors,
        strokewidth = 0,
        strokecolor = :transparent,
        shading = false,
        inspectable = c.inspectable,
        transparency = c.transparency
    )
end

function compute_triangulation(::DelaunayTriangulation, xs, ys)
    vertices = [xs'; ys']
    return MiniQhull.delaunay(vertices)
end

function compute_triangulation(triangulation::AbstractMatrix{<:Int}, xs, ys)
    if size(triangulation, 1) != 3
        throw(ArgumentError("Triangulation matrix must be of size (3, n) but is of size $(size(triangulation))."))
    end
    triangulation
end

# FIXME: TriplotBase augments levels so here the implementation is just repeated without that step
function filled_tricontours(x, y, z, t, levels)
    m = TriplotBase.TriMesh(x, y, t)
    filled_tricontours(m, z, levels)
end

function filled_tricontours(m::TriplotBase.TriMesh, z, levels)
    @assert issorted(levels)
    nlevels = length(levels)
    filled_contours = TriplotBase.FilledContour{eltype(levels)}[]
    for i=1:nlevels-1
        lower = levels[i]
        upper = levels[i+1]
        push!(filled_contours, TriplotBase.generate_filled_contours(m, z, lower, upper))
    end
    filled_contours
end
