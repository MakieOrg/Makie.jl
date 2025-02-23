struct DelaunayTriangulation end

"""
    tricontour(triangles::Triangulation, zs; kwargs...)
    tricontour(xs, ys, zs; kwargs...)

Plots a tricontour (lines only) of the height information in `zs` at the horizontal positions `xs` and
vertical positions `ys`. A `Triangulation` from DelaunayTriangulation.jl can also be provided instead of `xs` and `ys`
for specifying the triangles, otherwise an unconstrained triangulation of `xs` and `ys` is computed.
"""
@recipe Tricontour begin
    
    "Can be either an `Int` which results in n contour lines with equally spaced levels,
     or it can be an `AbstractVector{<:Real}` that lists n consecutive levels"
    levels = 10
    "Sets the width of the line in pixel units"
    linewidth = 1.0
    """
    Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`.
    These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`.
    For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

    For custom patterns have a look at [`Makie.Linestyle`](@ref).
    """
    linestyle = nothing
    """
    Sets the type of line cap used. Options are `:butt` (flat without extrusion),
    `:square` (flat with half a linewidth extrusion) or `:round`.
    """
    linecap = @inherit linecap
    """
    Controls the rendering at corners. Options are `:miter` for sharp corners,
    `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    joinstyle = @inherit joinstyle
    "Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`."
    miter_limit = @inherit miter_limit
    "Enables depth write for :iso so that volume correctly occludes other objects."
    enable_depth = true
    """
    Sets the way in which a vector of levels is interpreted,
    if it's set to `:relative`, each number is interpreted as a fraction
    between the minimum and maximum values of `zs`.
    For example, `levels = 0.1:0.1:1.0` would exclude the lower 10% of data.
    """
    mode = :normal
    """
    The color of the contour lines. If `nothing`, the color is determined by the numerical values of the
    contour levels in combination with `colormap` and `colorrange`.
    """
    color = nothing
    """
    A tuple with two min and max values of z to use in colormap. If `nothing`, the colorrange is determined from the minimum and maximum values in z
    """
    colorrange = nothing
    "Sets the colormap from which the line colors are sampled."
    colormap = @inherit colormap
    "Color transform function"
    colorscale = identity
    """The alpha (transparency) value of the colormap or color attribute."""
    alpha = 1.0
    
    """
    This sets the color of an optional additional contour line for
    zs = `minimum(zs)`.
    If it's `:auto`, the lower end of the colormap is picked
    and the remaining colors are shifted accordingly.
    If it's any color representation, this color is used.
    If it's `nothing`, no line is added.
    """
    extendlow = nothing
    """
    This sets the color of an optional additional contour line for
    zs = `maximum(zs)`.
    If it's `:auto`, the high end of the colormap is picked
    and the remaining colors are shifted accordingly.
    If it's any color representation, this color is used.
    If it's `nothing`, no band is added.
    """
    extendhigh = nothing
    nan_color = :transparent
    """
    The mode with which the points in `xs` and `ys` are triangulated.
    Passing `DelaunayTriangulation()` performs a Delaunay triangulation.
    You can also pass a preexisting triangulation as an `AbstractMatrix{<:Int}`
    with size (3, n), where each column specifies the vertex indices of one triangle,
    or as a `Triangulation` from DelaunayTriangulation.jl.
    """
    triangulation = DelaunayTriangulation()
    MakieCore.mixin_generic_plot_attributes()...
    
end

function Makie.used_attributes(
    ::Type{<:Tricontour}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}, ::AbstractVector{<:Real}
    )
    return (:triangulation,)
end

function Makie.convert_arguments(
    ::Type{<:Tricontour}, x::AbstractVector{<:Real}, y::AbstractVector{<:Real}, z::AbstractVector{<:Real};
    triangulation=DelaunayTriangulation())
    T = float_type(x, y, z)
    z = elconvert(T, z)
    points = [elconvert(T, x)'; elconvert(T, y)']
    if triangulation isa DelaunayTriangulation
        tri = DelTri.triangulate(points, randomise = false)
    elseif !(triangulation isa DelTri.Triangulation)
        # Wrap user's provided triangulation into a Triangulation.
        # Their triangulation must be such that DelTri.add_triangle! is defined.
        if typeof(triangulation) <: AbstractMatrix{<:Int} && size(triangulation, 1) != 3
            triangulation = triangulation'
        end
        tri = DelTri.Triangulation(points)
        triangles = DelTri.get_triangles(tri)
        for τ in eachcol(triangulation)
            DelTri.add_triangle!(triangles, τ)
        end
    end
    return (tri, z)
end

function compute_contour_colormap(levels, cmap, elow, ehigh)
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

function Makie.plot!(c::Tricontour{<:Tuple{<:DelTri.Triangulation, <:AbstractVector{<:Real}}})
    tri, zs = c[1:2]
    # FIXME: This uses _get_isoband_levels, from contourf.jl. 
    # This should be moved to an utils.jl file
    # Same issue is found in tricontourf.jl
    if typeof(c.levels[]) <: Integer
        c.levels[] += 1
    end
    c.attributes[:_computed_levels] = lift(c, zs, c.levels, c.mode) do zs, levels, mode
        return _get_isoband_levels(Val(mode), levels, vec(zs))
    end


    colorrange = lift(c, c._computed_levels, zs) do computed_levels, zs
        if length(computed_levels) == 1
            # Ensure a valid range using zs' extrema
            mi, ma = extrema_nan(zs)
            
            return [prevfloat(mi), nextfloat(ma)]  # Ensures min-max spacing
        end
        # Normal case
        mi, ma = extrema_nan(computed_levels)  
        return [prevfloat(prevfloat(mi)), nextfloat(nextfloat(ma))]
    end


    computed_colormap = lift(compute_contour_colormap, c, c._computed_levels, c.colormap, c.extendlow,
                             c.extendhigh)
    c.attributes[:_computed_colormap] = computed_colormap

    lowcolor = Observable{RGBAf}()
    lift!(compute_lowcolor, c, lowcolor, c.extendlow, c.colormap)
    c.attributes[:_computed_extendlow] = lowcolor
    is_extended_low = lift(!isnothing, c, c.extendlow)

    highcolor = Observable{RGBAf}()
    lift!(compute_highcolor, c, highcolor, c.extendhigh, c.colormap)
    c.attributes[:_computed_extendhigh] = highcolor
    is_extended_high = lift(!isnothing, c, c.extendhigh)

    points = Observable(Point2f[])
    colors = Observable(Float64[])
    
    function calculate_points(triangulation, zs, levels::Vector{Float32}, is_extended_low, is_extended_high)  
        empty!(points[])
        empty!(colors[])

        levels = copy(levels)

        # adjust outer levels to be inclusive
        levels[1] = prevfloat(levels[1])
        levels[end] = nextfloat(levels[end])
        is_extended_low && pushfirst!(levels, -Inf)
        is_extended_high && push!(levels, Inf)

        xs = [DelTri.getx(p) for p in DelTri.each_point(triangulation)] # each_point preserves indices
        ys = [DelTri.gety(p) for p in DelTri.each_point(triangulation)]

        trianglelist = compute_triangulation(triangulation)
        contour_lines = line_tricontours(xs, ys, zs, trianglelist, levels)

        # TODO: Fix the issue with colors here
        # contour_lines may contain multiple lines per level, each in a vector
        # Convert to a flat vector of points separated by NaNs
        for (fc, lc) in zip(contour_lines, levels)
            pointvecs = map(fc.polylines) do vecs
                map(Point2f, vecs)
            end
            if isempty(pointvecs)
                continue
            end
            for pointvec in pointvecs                
                append!(points[], pointvec)
                push!(points[], Point2f(NaN32))
                append!(colors[], (fill(lc, length(pointvec) + 1)))                     
            end            
        end
        # Remove last NaNs
        pop!(points[])
        pop!(colors[])

        notify(points)
        return
    end

    onany(calculate_points, c, tri, zs, c._computed_levels, is_extended_low, is_extended_high)
    
    # onany doesn't get called without a push, so we call
    # it on a first run!
    calculate_points(tri[], zs[], c._computed_levels[], is_extended_low[], is_extended_high[])    

    # TODO: add labels. See contours.jl
    # TODO: contour!() and tricontourf!() have different implemenations. Choose one to use here
    # TODO: refactor contour.jl, contourf.jl, tricontour.jl. tricontourf.jl and move common functions to an utils file.
    # FIXME: fix 

   
    color_args_computed = (
        comp_color = colors,
        comp_colormap =  c._computed_colormap,
        comp_colorscale =  c.colorscale,
        comp_colorrange = colorrange
    )

    final_color_args = process_color_args(
        c, colors; color_args_computed...)
    
    _colorcase = final_color_args[:_colorcase]
    atr = shared_attributes(c, Lines)
    
    if _colorcase === 1
        atr[:color] = final_color_args[:color]
    else
        for (k,v) in pairs(final_color_args)
            atr[k] = v
        end
        _colorcase = pop!(atr, :_colorcase)
    end

    @show atr
    lines!(
        c,
        atr,
        points,
    )
end

function compute_triangulation(tri)
    return [T[j] for T in DelTri.each_solid_triangle(tri), j in 1:3]'
end

# FIXME: TriplotBase.tricontour augments levels so here the implementation is repeated without that step
function line_tricontours(x, y, z, t, levels)
    m = TriplotBase.TriMesh(x, y, t)
    return line_tricontours(m, z, levels)
end

function line_tricontours(m::TriplotBase.TriMesh, z, levels)
    contours = TriplotBase.Contour{eltype(levels)}[]
    for level in levels
        push!(contours, TriplotBase.generate_unfilled_contours(m, z, level))
    end
    return contours
end

function process_color_args(c, colors; kwargs...)
    """ Process color arguments from user call and computed values"""

    color = get(c, :color, nothing)

    # Case 1: Single color is provided: ignore colormap, colorscale, colorrange
    if !isnothing(to_color(to_value(color)))
        println("CASE 1")
        return (_colorcase = 1, color = color)
    end

    colormap = get(c, :colormap, nothing)
    colorscale = get(c, :colorscale, nothing)
    colorrange = get(c, :colorrange, nothing)

    if isnothing(to_value(colormap))
        colormap = kwargs[:computed_colormap]
    end

    if isnothing(to_value(colorscale))
        colorscale = kwargs[:colorscale]
    end

    if isnothing(to_value(colorrange))
        colorrange = kwargs[:comp_colorrange]
    end

    return (
        _colorcase = 2,
        color = colors,
        colormap = colormap,
        colorscale = colorscale,
        colorrange = colorrange
    )
end
