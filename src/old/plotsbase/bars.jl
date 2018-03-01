
function bar(d, kw_args)
    x, y = d[:x], d[:y]
    nx, ny = length(x), length(y)
    axis = d[:subplot][isvertical(d) ? :xaxis : :yaxis]
    cv = [discrete_value!(axis, xi)[1] for xi=x]
    x = if nx == ny
        cv
    elseif nx == ny + 1
        0.5diff(cv) + cv[1:end-1]
    else
        error("bar recipe: x must be same length as y (centers), or one more than y (edges).\n\t\tlength(x)=$(length(x)), length(y)=$(length(y))")
    end
    if haskey(kw_args, :stroke_width) # stroke is inside for bars
        #kw_args[:stroke_width] = -kw_args[:stroke_width]
    end
    # compute half-width of bars
    bw = nothing
    hw = if bw == nothing
        ignorenan_mean(diff(x))
    else
        Float64[_cycle(bw,i)*0.5 for i=1:length(x)]
    end

    # make fillto a vector... default fills to 0
    fillto = d[:fillrange]
    if fillto == nothing
        fillto = 0
    end
    # create the bar shapes by adding x/y segments
    positions, scales = Array{Point2f0}(ny), Array{Vec2f0}(ny)
    m = Reactive.value(kw_args[:model])
    sx, sy = m[1,1], m[2,2]
    for i=1:ny
        center = x[i]
        hwi = abs(_cycle(hw,i)); yi = y[i]; fi = _cycle(fillto,i)
        if Plots.isvertical(d)
            sz = (hwi*sx, yi*sy)
        else
            sz = (yi*sx, hwi*2*sy)
        end
        positions[i] = (center-hwi*0.5, fi)
        scales[i] = sz
    end

    kw_args[:scale] = scales
    kw_args[:offset] = Vec2f0(0)
    visualize((GLVisualize.RECTANGLE, positions), Style(:default), kw_args)
    #[]
end



const _box_halfwidth = 0.4

notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

function boxplot(d, kw_args)
    kwbox = copy(kw_args)
    range = 1.5; notch = false
    x, y = d[:x], d[:y]
    glabels = sort(collect(unique(x)))
    warning = false
    outliers_x, outliers_y = zeros(0), zeros(0)

    box_pos = Point2f0[]
    box_scale = Vec2f0[]
    outliers = Point2f0[]
    t_segments = Point2f0[]
    m = Reactive.value(kw_args[:model])
    sx, sy = m[1,1], m[2,2]
    for (i,glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]
        # compute quantiles
        q1,q2,q3,q4,q5 = quantile(values, linspace(0,1,5))
        # notch
        n = Plots.notch_width(q2, q4, length(values))
        # warn on inverted notches?
        if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
            warn("Boxplot's notch went outside hinges. Set notch to false.")
            warning = true # Show the warning only one time
        end

        # make the shape
        center = Plots.discrete_value!(d[:subplot][:xaxis], glabel)[1]
        hw = d[:bar_width] == nothing ? Plots._box_halfwidth*2 : _cycle(d[:bar_width], i)
        l, m, r = center - hw/2, center, center + hw/2

        # internal nodes for notches
        L, R = center - 0.5 * hw, center + 0.5 * hw
        # outliers
        if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
            limit = range*(q4-q2)
            inside = Float64[]
            for value in values
                if (value < (q2 - limit)) || (value > (q4 + limit))
                    push!(outliers, (center, value))
                else
                    push!(inside, value)
                end
            end
            # change q1 and q5 to show outliers
            # using maximum and minimum values inside the limits
            q1, q5 = ignorenan_extrema(inside)
        end
        # Box
        if notch
            push!(t_segments, (m, q1), (l, q1), (r, q1), (m, q1), (m, q2))# lower T
            push!(box_pos, (l, q2));push!(box_scale, (hw*sx, n*sy)) # lower box
            push!(box_pos, (l, q4));push!(box_scale, (hw*sx, n*sy)) # upper box
            push!(t_segments, (m, q5), (l, q5), (r, q5), (m, q5), (m, q4))# upper T

        else
            push!(t_segments, (m, q2), (m, q1), (l, q1), (r, q1))# lower T
            push!(box_pos, (l, q2)); push!(box_scale, (hw*sx, (q3-q2)*sy)) # lower box
            push!(box_pos, (l, q4)); push!(box_scale, (hw*sx, (q3-q4)*sy)) # upper box
            push!(t_segments, (m, q4), (m, q5), (r, q5), (l, q5))# upper T
        end
    end
    kwbox = Dict{Symbol, Any}(
        :scale => box_scale,
        :model => kw_args[:model],
        :offset => Vec2f0(0),
    )
    extract_marker(d, kw_args)
    outlier_kw = Dict(
        :model => kw_args[:model],
        :color =>  scalar_color(d, :fill),
        :stroke_width => Float32(d[:markerstrokewidth]),
        :stroke_color => scalar_color(d, :markerstroke),
    )
    lines_kw = Dict(
        :model => kw_args[:model],
        :stroke_width =>  d[:linewidth],
        :stroke_color =>  scalar_color(d, :fill),
    )
    vis1 = GLVisualize.visualize((GLVisualize.RECTANGLE, box_pos), Style(:default), kwbox)
    vis2 = GLVisualize.visualize((GLVisualize.CIRCLE, outliers), Style(:default), outlier_kw)
    vis3 = GLVisualize.visualize(t_segments, Style(:linesegment), lines_kw)
    [vis1, vis2, vis3]
end
