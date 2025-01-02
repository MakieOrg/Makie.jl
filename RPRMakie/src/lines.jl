function line2segments(points)
    npoints = length(points)
    indices = RPR.rpr_int[]
    count = 0
    for i in 1:npoints
        push!(indices, i - 1)
        count += 1
        if count == 4 && !(i == npoints)
            push!(indices, i - 1)
            count = 1
        end
    end
    missing_points = 4 - (length(indices) % 4)
    if missing_points != 4
        append!(indices, fill(last(indices), missing_points))
    end
    return indices
end

function to_rpr_object(context, matsys, scene, plot::Makie.Lines)
    points = decompose(Point3f, to_value(plot[1]))
    isempty(points) && return nothing
    npoints = length(points)
    indices = line2segments(points)
    radius = [plot.linewidth[] / 1000]
    curve = RPR.Curve(context, points, indices, radius, [Vec2f(0.0)], [length(indices) ÷ 4])
    material = extract_material(matsys, plot)
    material.color = to_color(plot.color[])
    set!(curve, material)
    return curve
end

function to_rpr_object(context, matsys, scene, plot::Makie.LineSegments)
    arg1 = to_value(plot[1])
    isempty(arg1) && return nothing
    points = decompose(Point3f, arg1)
    segments = TupleView{2, 2}(RPR.rpr_int(0):RPR.rpr_int(length(points) - 1))
    indices = RPR.rpr_int[]

    for (a, b) in segments
        push!(indices, a, a, b, b)
    end

    nsegments = length(indices) ÷ 4

    radius = if plot.linewidth[] isa AbstractVector
        lw = plot.linewidth[]
        perseg = if length(lw) == length(points)
            lw[1:2:end]
        elseif length(lw) == nsegments
            lw
        else
            error("Length $(nsegments) doesn't match $(length(lw))")
        end
        Float32.(lw ./ 1000)
    else
        fill(Float32(plot.linewidth[] / 1000), nsegments)
    end

    curve = RPR.Curve(
        context, points, indices, radius, Vec2f.(0.0, LinRange(0, 1, nsegments)),
        fill(1, nsegments)
    )
    material = extract_material(matsys, plot)
    color = to_color(plot.color[])

    function set_color!(colorvec)
        isempty(colorvec) && return
        tex = RPR.ImageTextureMaterial(matsys)
        ncols = length(colorvec)
        img = RPR.Image(context, reshape(colorvec, (ncols, 1)))
        tex.data = img
        material.color = tex
        return
    end

    if color isa AbstractVector{<:Colorant}
        set_color!(copy(color))
    elseif color isa AbstractVector{<:Number}
        sampler = Makie.sampler(to_colormap(plot.colormap[]), color; scaling = Makie.Scaling(identity, plot.colorrange[]))
        set_color!(collect(sampler))
    else
        material.color = to_color(color)
    end
    set!(curve, material)
    return curve
end
