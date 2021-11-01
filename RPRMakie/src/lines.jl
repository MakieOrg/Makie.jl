function line2segments(points)
    indices = RPR.rpr_int[]
    last_idx = 0
    nsegs = length(points) ÷ 4
    for seg in 1:nsegs
        append!(indices, last_idx .+ (0:3))
        last_idx += 3
    end
    missing_points = 4 - (length(points) % 4)
    append!(indices, fill(last(indices), missing_points))
    return indices
end

function to_rpr_object(context, matsys, scene, plot::Makie.Lines)
    points = to_value(plot[1])
    isempty(points) && return nothing
    npoints = length(points)
    indices = RPR.rpr_int(0):RPR.rpr_int(npoints-1)

    if npoints % 4 != 0
        missing_points = 4 - (npoints % 4)
        indices = [indices; fill(last(indices), missing_points)]
    end

    segments = TupleView{4, 3}(indices)

    indices = reinterpret(RPR.rpr_int, segments)
    radius = [plot.linewidth[]]
    curve = RPR.Curve(context, points, indices, radius, [Vec2f(0.0)], [length(segments)])
    material = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_DIFFUSE)
    set!(material, RPR.RPR_MATERIAL_INPUT_COLOR, to_color(plot.color[]))
    set!(curve, material)
    return curve
end

function to_rpr_object(context, matsys, scene, plot::Makie.LineSegments)
    points = to_value(plot[1])
    segments = TupleView{2, 2}(RPR.rpr_int(0):RPR.rpr_int(length(points)-1))
    indices = RPR.rpr_int[]

    for (a, b) in segments
        push!(indices, a, a, b, b)
    end

    radius = if plot.linewidth[] isa AbstractVector
        [plot.linewidth[][1]/1000]
    else
        [plot.linewidth[]/1000]
    end

    curve = RPR.Curve(context, points, indices, radius, [Vec2f(0.0)], [length(points)÷2])
    material = RPR.MaterialNode(matsys, RPR.RPR_MATERIAL_NODE_DIFFUSE)
    color = plot.color[] isa AbstractVector ? plot.color[][1] : plot.color[]
    set!(material, RPR.RPR_MATERIAL_INPUT_COLOR, to_color(color))
    set!(curve, material)
    return curve
end
