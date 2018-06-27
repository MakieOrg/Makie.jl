notch_width(q2, q4, N) = 1.58 * (q4-q2)/sqrt(N)

pair_up(dict, key) = (key => dict[key])

function extract(parent::Attributes, keys::NTuple{N, Symbol}) where N
    vals = getindex.(parent, keys)
    Attributes(zip(keys, vals))
end


function plot!(scene::Scene, ::Val{:boxplot}, attributes::Attributes, x, y, z)
    # Merge custom, user defined attributes with the theme for the boxplot!
    # Theme will be inserted into the scene at first call and is available as a global
    # theme
    attributes, rest = merged_get!(:boxplot, scene, attributes) do
        Theme(
            notch = false,
            range = 1.5,
            outliers = true,
            whisker_width = :match,
            bar_width = 0.8,
            markershape = :circle,
            strokecolor = :black,
        )
    end

    glabels = sort(collect(unique(x)))
    warning = false
    outliers_x, outliers_y = zeros(0), zeros(0)
    bw = attributes[:bar_width]
    if whisker_width == :match || whisker_width >= 0
        error("whisker_width must be :match or a positive number")
    end
    ww = whisker_width == :match ? bw : whisker_width
    boxes = FRect2D[]
    t_segments = Point2f0[]
    for (i, glabel) in enumerate(glabels)
        # filter y
        values = y[filter(i -> _cycle(x,i) == glabel, 1:length(y))]
        # compute quantiles
        q1, q2, q3, q4, q5 = quantile(values, linspace(0,1,5))
        # notch
        n = notch_width(q2, q4, length(values))
        # warn on inverted notches?
        if notch && !warning && ( (q2>(q3-n)) || (q4<(q3+n)) )
            warn("Boxplot's notch went outside hinges. Set notch to false.")
            warning = true # Show the warning only one time
        end

        # make the shape
        center = Plots.discrete_value!(attributes[:subplot][:xaxis], glabel)[1]
        hw = 0.5 * _cycle(bw, i) # Box width
        HW = 0.5 * _cycle(ww, i) # Whisker width
        l, m, r = center - hw, center, center + hw
        lw, rw = center - HW, center + HW

        # internal nodes for notches
        L, R = center - 0.5 * hw, center + 0.5 * hw

        # outliers
        if Float64(range) != 0.0  # if the range is 0.0, the whiskers will extend to the data
            limit = range*(q4-q2)
            inside = Float64[]
            for value in values
                if (value < (q2 - limit)) || (value > (q4 + limit))
                    if outliers
                        push!(outliers_y, value)
                        push!(outliers_x, center)
                    end
                else
                    push!(inside, value)
                end
            end
            # change q1 and q5 to show outliers
            # using maximum and minimum values inside the limits
            q1, q5 = Plots.ignorenan_extrema(inside)
        end

        # Box
        if notch
            push!(t_segments, (m, q1), (l, q1), (r, q1), (m, q1), (m, q2))# lower T
            push!(boxes, FRext(l, q2, hw*sx, n*sy)) # lower box
            push!(boxes, FRext(l, q4, hw*sx, n*sy)) # lower box
            push!(t_segments, (m, q5), (l, q5), (r, q5), (m, q5), (m, q4))# upper T
        else
            push!(t_segments, (m, q2), (m, q1), (l, q1), (r, q1))# lower T
            push!(boxes, FRext(l, q2, hw*sx, (q3-q2)*sy))
            push!(boxes, FRext(l, q4, hw*sx, (q3-q4)*sy))
            push!(t_segments, (m, q4), (m, q5), (r, q5), (l, q5))# upper T
        end
    end
    # Outliers
    subscene = Scene(scene)
    if outliers
        plot!(
            subscene, Scatter,
            extract(attributes, (:color, :strokecolor, :markershape))
            outliers_x, outliers_y,
        )
    end
    plot!(
        subscene, Lines, boxes,
        color = attributes[:strokecolor],
        linewidth = attributes[:strokewidth]
    )
    plot!(
        subscene, Poly,
        extract(attributes, (:color, :strokecolor, :strokewidth)),
        boxes
    )
    subscene
end




function update_ticks_guides(d::KW, labs, i, j, n)
    # d[:title]  = (i==1 ? _cycle(labs,j) : "")
    # d[:xticks] = (i==n)
    d[:xguide] = (i==n ? _cycle(labs,j) : "")
    # d[:yticks] = (j==1)
    d[:yguide] = (j==1 ? _cycle(labs,i) : "")
end

function plot!(scene::Scene, ::Type{CorrPlot}, attributes::Attributes, mat)
    mat = cp.args[1]
    n = size(mat, 2)
    C = cor(mat)
    attributes, plot_att = merged_get!(:boxplot, scene, attributes) do
        Theme(
            link = :x,  # need custom linking for y
            layout = (n,n),
            legend = false,
            margin = 1mm,
            titlefont = font(11),
            fillcolor = attributes[:color],
            linecolor = attributes[:],
            markeralpha = 0.4,
            grad = cgrad(get(attributes, :markercolor, cgrad())),
            indices = reshape(1:n^2, n, n)',
            title = "",
        )
    end
    # this is simples way to overwrite plot defaults from the global theme,
    # but still allow user owerwrites
    subscene = Scene(scene, theme = Theme(
        get!(plot_att, k, v)
    ))

    labs = pop!(attributes, :label, [""])
    plotgrid = broadcast(1:n, (1:n)') do i, j
        vi = view(mat,:,i)
        vj = view(mat,:,j)
        if i == j # histograms are on the diagonal
            histogram!(subscene, vi, grid = false)
        elseif i > j
            scatter!(subscene, vj, vi)
        else
            plot!(subscene, vj, vi, seriestype = attributes[:seriestype])
        end
    end
    plot!(scene, rest, plotgrid)
end


function plot!(plot::CorrPlot)
    mat = plot[1]
    n = size(mat, 2)
    C = cor(mat)
    plotgrid = broadcast(1:n, (1:n)') do i, j
        vi = view(mat,:,i)
        vj = view(mat,:,j)
        if i == j # histograms are on the diagonal
            histogram!(plot, vi, grid = false)
        elseif i > j
            scatter!(plot, vj, vi, markercolor = grad[0.5 + 0.5C[i,j]])
        else
            plot!(plot, vj, vi, seriestype = attributes[:seriestype])
        end
    end
    plot!(plotgrid) # matrix of plots -> gridlayout
end
