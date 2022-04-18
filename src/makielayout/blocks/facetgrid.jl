function initialize_block!(fg::FacetGrid, rows, columns;
        sharex = :all,
        sharey = :all,
        xlabel = "x",
        ylabel = "y")

    scene = fg.blockscene

    layout = fg.layout
    layout.block_updates = true
    axs = map(Iterators.product(1:rows, 1:columns)) do (i, j)
        Axis(layout[i, j])
    end
    fg.axes = axs

    if sharex == :all
        linkxaxes!(axs...)
        for c in axs[1:end-1, :]
            hidexdecorations!(c, grid = false)
        end
    elseif sharex == :cols
        for col in eachcol(axs)
            linkxaxes!(col...)
            for c in col[1:end-1]
                hidexdecorations!(c, grid = false)
            end
        end
    elseif sharex == :none
    else
        error("Unknown sharex $(repr(sharex)), only :all, :cols, :none allowed.")
    end

    if sharey == :all
        linkyaxes!(axs...)
        for c in axs[:, 2:end]
            hideydecorations!(c, grid = false)
        end
    elseif sharey == :rows
        for row in eachrow(axs)
            linkyaxes!(row...)
            for r in row[2:end]
                hideydecorations!(r, grid = false)
            end
        end
    elseif sharey == :none
    else
        error("Unknown sharey $(repr(sharey)), only :all, :rows, :none allowed.")
    end

    bottomprotrusions = map(protrusionsobservable, axs[end, :])
    xlabel_padding = lift(bottomprotrusions...) do prots...
        b = maximum(x -> x.bottom, prots)
        (0f0, 0f0, 0f0, b + 5)
    end

    leftprotrusions = map(protrusionsobservable, axs[:, 1])
    ylabel_padding = lift(leftprotrusions...) do prots...
        l = maximum(x -> x.left, prots)
        (0f0, l + 5, 0f0, 0f0)
    end

    Label(layout[end, :, Bottom()], xlabel, padding = xlabel_padding)
    Label(layout[:, 1, Left()], ylabel, rotation = pi/2, padding = ylabel_padding)

    topboxes = map(axes(axs, 2)) do col
        Box(layout[1, col, Top()], height = 30, color = :gray90)
    end
    toplabels = map(axes(axs, 2)) do col
        Label(layout[1, col, Top()])
    end

    rightboxes = map(axes(axs, 1)) do row
        Box(layout[row, end, Right()], width = 30, color = :gray90)
    end
    rightlabels = map(axes(axs, 1)) do row
        Label(layout[row, end, Right()], rotation = -pi/2)
    end

    on(fg.columnlabels) do labels
        if labels === Makie.automatic
            for (i, tl) in enumerate(toplabels)
                tl.text = "$i"
            end
        else
            if length(labels) != size(axs, 2)
                throw(ArgumentError("Got $(length(labels)) column labels but $(size(axs, 2)) columns."))
            end
            for (i, tl) in enumerate(toplabels)
                tl.text = labels[i]
            end
        end
    end
    on(fg.rowlabels) do labels
        if labels === Makie.automatic
            for (i, tl) in enumerate(rightlabels)
                tl.text = "$i"
            end
        else
            if length(labels) != size(axs, 1)
                throw(ArgumentError("Got $(length(labels)) row labels but $(size(axs, 1)) rows."))
            end
            for (i, tl) in enumerate(rightlabels)
                tl.text = labels[i]
            end
        end
    end
    notify(fg.columnlabels)
    notify(fg.rowlabels)


    layout.block_updates = false
    GridLayoutBase.update!(layout)

    return
end

Base.getindex(fg, args...) = getindex(fg.axes, args...)