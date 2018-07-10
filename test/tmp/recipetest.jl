




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
