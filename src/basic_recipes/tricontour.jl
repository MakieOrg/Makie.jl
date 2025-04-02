struct DelaunayTriangulation end

"""
    tricontour(triangles::Triangulation, zs; kwargs...)
    tricontour(xs, ys, zs; kwargs...)

Plots a tricontour (lines only) of the height information in `zs` at the horizontal positions `xs` and
vertical positions `ys`. A `Triangulation` from DelaunayTriangulation.jl can also be provided instead of `xs` and `ys`
for specifying the triangles, otherwise an unconstrained triangulation of `xs` and `ys` is computed.
"""
@recipe Tricontour begin
    """
    If `true`, adds text labels to the contour lines.
    """
    labels = false
    """
    If `true`, lines are partially deleted when text labels are added to the contour lines.
    """
    inline = true    
    "The font of the contour labels."
    labelfont = @inherit font
    "Color of the contour labels, if `nothing` it matches `color` by default."
    labelcolor = nothing  # matches color by default
    """
    Formats the numeric values of the contour levels to strings.
    """
    labelformatter = contour_label_formatter
    "Font size of the contour labels"
    labelsize = 10 # arbitrary
    
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
    contour levels in combination with `colormap` and `colorrange`. If a `color` argument is specified, values of arguments `colorrange`, `colormap`, `colorscale` and `discretize_colormap` are ignored.
    """
    color = nothing
    """
    A tuple with two min and max values of z to use in colormap. If `nothing`, the colorrange is determined from the minimum and maximum values in z
    """
    colorrange = nothing
    "Sets the colormap from which the line colors are sampled."
    colormap = @inherit colormap

    """
    Determines whether the given colormap should be discretized based on contour levels. 

    - If `true`, a discrete (categorical) colormap is generated, where colors are assigned based on the provided contour levels.
    - If `false`, the given colormap is used  without discretization.

    This setting is useful for categorical or stepped visualizations where distinct colors are needed for each contour level.
    """
    discretize_colormap = true

    "Color transform function"
    colorscale = identity
    """The alpha (transparency) value of the colormap or color attribute."""
    alpha = 1.0
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

function compute_contour_colormap(levels, cmap, discretize_colormap)

    if !discretize_colormap || length(levels)==1
        return cgrad(cmap)
    end

    levels_scaled = (levels .- minimum(levels)) ./ (maximum(levels) - minimum(levels))

    _cmap = to_colormap(cmap)
    return cgrad(_cmap, levels_scaled; categorical=true)
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


    computed_colormap = lift(
        compute_contour_colormap, c, c._computed_levels,
        c.colormap, c.discretize_colormap
        )
    
    c.attributes[:_computed_colormap] = computed_colormap

    points = Observable(Point2f[])
    colors = Observable(Float64[])
    lev_pos = Observable(Tuple{Float32,NTuple{3,Point3f}}[])

    labels = c.attributes[:labels]
    inline = c.attributes[:inline]

    function calculate_points(triangulation, zs, levels::Vector{Float32})  
        empty!(points[])
        empty!(colors[])
        empty!(lev_pos[])
        levels = copy(levels)

        # adjust outer levels to be inclusive
        levels[1] = prevfloat(levels[1])
        levels[end] = nextfloat(levels[end])


        xs = [DelTri.getx(p) for p in DelTri.each_point(triangulation)] # each_point preserves indices
        ys = [DelTri.gety(p) for p in DelTri.each_point(triangulation)]

        trianglelist = compute_triangulation(triangulation)
        contour_lines = line_tricontours(xs, ys, zs, trianglelist, levels)
    
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
                labels[] && push!(lev_pos[], label_info(lc, pointvec))
            end            
        end

        if length(points[]) == 0
            throw(ArgumentError("No contour lines found for the given `levels`. Ensure that `z` contains values within the specified range."))
        end      

        # Remove last NaNs
        pop!(points[])
        pop!(colors[])

        # Update observables
        notify(points)
        notify(colors)
        labels[] && notify(lev_pos)
        return
    end

    # Prepare color arguments
    color_args_computed = (
        comp_color = colors,
        comp_colorscale =  c.colorscale,
        comp_colorrange = colorrange
    )
    atr = shared_attributes(c, Lines)
    process_color_args!(atr, c, colors; color_args_computed...)

    # Compute contours
    onany(calculate_points, c, tri, zs, c._computed_levels)
    
    # onany doesn't get called without a push, so we call
    # it on a first run!
    calculate_points(tri[], zs[], c._computed_levels[])
    @extract c (labelsize, labelfont, labelcolor, labelformatter)

    texts = text!(
        c,
        Observable(Point2f[]);
        color = Observable(RGBA{Float32}[]),
        rotation = Observable(Float32[]),
        text = Observable(String[]),
        align = (:center, :center),
        fontsize = labelsize,
        font = labelfont,
        transform_marker = false
    )

    # (code for labels is adapted from contours.jl)
    # Update label observables whenever lev_pos changes
    scene = parent_scene(c)
    space = c.space[]
    
    lift(
    c, scene.camera.projectionview, transformationmatrix(c), scene.viewport,
    labels, labelcolor, labelformatter, lev_pos
    ) do _, _, _, labels, labelcolor, labelformatter, lev_pos
        labels || return
        # Clear previous data
        empty!(texts.positions[])
        empty!(texts.text[])
        empty!(texts.rotation[])
        empty!(texts.color[])

        # Update text for labels
        texts.text[] = [labelformatter(lp[1]) for lp in lev_pos]
        
        # Update color for labels
        if isnothing(to_value(labelcolor))
            # Compute color for each label to use when labelcolor is set to nothing
            cm = to_colormap(atr[:colormap][])
            colscale = atr[:colorscale][]
            colrange = Tuple(colscale.(atr[:colorrange][]))
            texts.color[] = [interpolated_getindex(cm, colscale(lp[1]), colrange) for lp in lev_pos]
        else
            texts.color[] = fill(to_color(labelcolor), length(lev_pos))
        end

        # Update rotation angle and position for labels
        for (lev, (p1, p2, p3)) in lev_pos
            px_pos1 = project(scene, apply_transform(transform_func(c), p1, space))
            px_pos3 = project(scene, apply_transform(transform_func(c), p3, space))
            rot_from_horz::Float32 = angle(px_pos1, px_pos3)
            # transition from an angle from horizontal axis in [-π; π]
            # to a readable text with a rotation from vertical axis in [-π / 2; π / 2]
            rot_from_vert::Float32 = if abs(rot_from_horz) > 0.5f0 * π
                rot_from_horz - copysign(Float32(π), rot_from_horz)
            else
                rot_from_horz
            end
            push!(texts.rotation[], rot_from_vert)

            p = p2  # try to position label around center
            isnan(p) && (p = p1)
            isnan(p) && (p = p3)
            push!(texts.positions[], p)
        end
        
        # Notify observables to propagate changes
        notify(texts.positions)
        notify(texts.text)
        notify(texts.color)
        notify(texts.rotation)
    end

    bboxes = lift(c, labels, inline, texts.text; ignore_equal_values=true) do labels, inline, _
        (labels && inline) || return
        return broadcast(texts.plots[1][1].val, texts.positions.val, texts.rotation.val) do gc, pt, rot
            # drop the depth component of the bounding box for 3D
            px_pos = project(scene, apply_transform(transform_func(c), pt, space))
            bb = unchecked_boundingbox(gc, to_ndim(Point3f, px_pos, 0f0), to_rotation(rot))
            isfinite_rect(bb) || return Rect2f()
            Rect2f(bb)
        end
    end
    
    masked_lines = lift(c, labels, inline, bboxes, points) do labels, inline, bboxes, segments
        (labels && inline) || return segments

        # Skip masking if bboxes is empty
        isempty(bboxes) && return segments
        # simple heuristic to turn off masking segments (≈ less than 10 pts per contour)
        count(isnan, segments) > length(segments) / 10 && return segments
        n = 1
        bb = bboxes[n]
        nlab = length(bboxes)
        masked = copy(segments)
        nan = Point2f(NaN32)
        for (i, p) in enumerate(segments)
            if isnan(p) && n < nlab
                bb = bboxes[n += 1]  # next segment is materialized by a NaN, thus consider next label
                # wireframe!(plot, bb, space = :pixel)  # toggle to debug labels
            elseif project(scene, apply_transform(transform_func(c), p, space)) in bb
                masked[i] = nan
                for dir in (-1, +1)
                    j = i
                    while true
                        j += dir
                        checkbounds(Bool, segments, j) || break
                        project(scene, apply_transform(transform_func(c), segments[j], space)) in bb || break
                        masked[j] = nan
                    end
                end
            end
        end
        masked
    end
    # Plot countour lines
    lines!(c, atr, masked_lines)
    return c
    # TODO: refactor contour.jl, contourf.jl, tricontour.jl. tricontourf.jl and move common functions to an utils file.
    # TODO: implement `inline` boolean parameter for labels of contour lines
    # TODO: add other methods to select placement of labels

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

function process_color_args!(atr, c, colors; kwargs...)
    """ Process color arguments from user call and computed values"""
    color = get(atr, :color, nothing)
    # Case 1: Single color is provided: ignore colormap, colorscale, colorrange
    if !isnothing(to_color(to_value(color)))
        # Use only :color. Remove other color attributes
        for k in (:colormap, :colorscale, :colorrange)
            haskey(atr, k) && delete!(atr, k)
        end
        return
    end
    # Case 2: use computed colors. Verify what other attributes were passed
    atr[:color] = colors
    atr[:colormap] = c.attributes[:_computed_colormap]
    colorrange = get(atr, :colorrange, nothing)
    if isnothing(to_value(colorrange))
        atr[:colorrange] = kwargs[:comp_colorrange]
    end
    return
end

function label_info(lev, vertices)
    """ Returns 3 middle points for each contour lines that are used to place labels"""
    # Adapted from contours.jl
    mid = ceil(Int, 0.5f0 * length(vertices))
    # take 3 pts around half segment
    pts = (vertices[max(firstindex(vertices), mid - 1)], vertices[mid], vertices[min(mid + 1, lastindex(vertices))])
    (
        lev,
        map(p -> to_ndim(Point3f, p, lev), Tuple(pts))
    )
end