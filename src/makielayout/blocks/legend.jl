function initialize_block!(leg::Legend; entrygroups)
    entry_groups = convert(Observable{Vector{Tuple{Any,Vector{LegendEntry}}}}, entrygroups)
    blockscene = leg.blockscene

    # by default, `tellwidth = true` and `tellheight = false` for vertical legends
    # and vice versa for horizontal legends
    real_tellwidth = @lift $(leg.tellwidth) === automatic ? $(leg.orientation) === :vertical : $(leg.tellwidth)
    real_tellheight = @lift $(leg.tellheight) === automatic ? $(leg.orientation) === :horizontal : $(leg.tellheight)
    setfield!(leg, :_tellheight, real_tellheight)
    setfield!(leg, :_tellwidth, real_tellwidth)

    legend_area = lift(round_to_IRect2D, blockscene, leg.layoutobservables.computedbbox)

    scene = Scene(blockscene, blockscene.viewport, camera = campixel!)

    # the rectangle in which the legend is drawn when margins are removed
    legendrect = lift(blockscene, legend_area, leg.margin) do la, lm
        enlarge(la, -lm[1], -lm[2], -lm[3], -lm[4])
    end

    backgroundcolor = if !isnothing(leg.bgcolor[])
        @warn("Keyword argument `bgcolor` is deprecated, use `backgroundcolor` instead.")
        leg.bgcolor
    else
        leg.backgroundcolor
    end

    bg = poly!(scene,
        legendrect,
        color = backgroundcolor, strokewidth = leg.framewidth, visible = leg.framevisible,
        strokecolor = leg.framecolor, inspectable = false)
    translate!(bg, 0, 0, -7) # bg behind patches but before content at 0 (legend is at +10)

    # the grid containing all content
    grid = GridLayout(bbox = legendrect, alignmode = Outside(leg.padding[]...))
    leg.grid = grid

    # while the entries are being manipulated through code, this Ref value is set to
    # true so the GridLayout doesn't update itself to save time
    manipulating_grid = Ref(false)

    on(blockscene, leg.padding) do p
        grid.alignmode = Outside(p...)
        relayout()
        return
    end

    update_grid = Observable(true)
    onany(blockscene, update_grid, leg.margin) do _, margin
        if manipulating_grid[]
            return
        end
        w = GridLayoutBase.determinedirsize(grid, GridLayoutBase.Col())
        h = GridLayoutBase.determinedirsize(grid, GridLayoutBase.Row())
        if !any(isnothing.((w, h)))
            leg.layoutobservables.autosize[] = (w + sum(margin[1:2]), h + sum(margin[3:4]))
        end
        return
    end

    # these arrays store all the plot objects that the legend entries need
    titletexts = Optional{Label}[]
    entrytexts = [Label[]]
    entryplots = [[AbstractPlot[]]]
    entryrects = [Box[]]

    function relayout()
        manipulating_grid[] = true

        rowcol(n) = ((n - 1) ÷ leg.nbanks[] + 1, (n - 1) % leg.nbanks[] + 1)

        for i in length(grid.content):-1:1
            GridLayoutBase.remove_from_gridlayout!(grid.content[i])
        end

        # loop through groups
        for g in 1:length(entry_groups[])
            title = titletexts[g]
            etexts = entrytexts[g]
            erects = entryrects[g]

            subgl = if leg.orientation[] === :vertical
                if leg.titleposition[] === :left
                    isnothing(title) || (grid[g, 1] = title)
                    grid[g, 2] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                elseif leg.titleposition[] === :top
                    isnothing(title) || (grid[2g - 1, 1] = title)
                    grid[2g, 1] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                end
            elseif leg.orientation[] === :horizontal
                if leg.titleposition[] === :left
                    isnothing(title) || (grid[1, 2g-1] = title)
                    grid[1, 2g] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                elseif leg.titleposition[] === :top
                    isnothing(title) || (grid[1, g] = title)
                    grid[2, g] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                end
            end

            for (n, (et, er)) in enumerate(zip(etexts, erects))
                i, j = leg.orientation[] === :vertical ? rowcol(n) : reverse(rowcol(n))
                subgl[i, 2j-1] = er
                subgl[i, 2j] = et
            end

            rowgap!(subgl, leg.rowgap[])
            for c in 1:ncols(subgl)-1
                colgap!(subgl, c, c % 2 == 1 ? leg.patchlabelgap[] : leg.colgap[])
            end
        end

        for r in 1:nrows(grid)-1
            if leg.orientation[] === :horizontal
                if leg.titleposition[] === :left
                    # nothing
                elseif leg.titleposition[] === :top
                    rowgap!(grid, r, leg.titlegap[])
                end
            elseif leg.orientation[] === :vertical
                if leg.titleposition[] === :left
                    rowgap!(grid, r, leg.groupgap[])
                elseif leg.titleposition[] === :top
                    rowgap!(grid, r, r % 2 == 1 ? leg.titlegap[] : leg.groupgap[])
                end
            end
        end
        for c in 1:ncols(grid)-1
            if leg.orientation[] === :horizontal
                if leg.titleposition[] === :left
                    colgap!(grid, c, c % 2 == 1 ? leg.titlegap[] : leg.groupgap[])
                elseif leg.titleposition[] === :top
                    colgap!(grid, c, leg.groupgap[])
                end
            elseif leg.orientation[] === :vertical
                if leg.titleposition[] === :left
                    colgap!(grid, c, leg.titlegap[])
                elseif leg.titleposition[] === :top
                    # nothing here
                end
            end
        end


        # delete unused rows and columns
        trim!(grid)


        manipulating_grid[] = false
        notify(update_grid)

        # translate the legend forward so it is above the standard axis content
        # which is at zero. this will not really work if the legend should be
        # above a 3d plot, but for now this hack is ok.
        translate!(scene, (0, 0, 10))
        return
    end

    onany(blockscene, leg.nbanks, leg.titleposition, leg.rowgap, leg.colgap, leg.patchlabelgap, leg.groupgap,
          leg.titlegap,
            leg.titlevisible, leg.orientation, leg.gridshalign, leg.gridsvalign) do args...
        relayout()
        return
    end

    on(blockscene, entry_groups) do entry_groups
        # first delete all existing labels and patches

        for t in titletexts
            !isnothing(t) && delete!(t)
        end
        empty!(titletexts)

        [delete!.(etexts) for etexts in entrytexts]
        empty!(entrytexts)

        [delete!.(erects) for erects in entrytexts]
        empty!(entryrects)

        # delete patch plots
        for eplotgroup in entryplots
            for eplots in eplotgroup
                # each entry can have a vector of patch plots
                delete!.(scene, eplots)
            end
        end
        empty!(entryplots)

        # the attributes for legend entries that the legend itself carries
        # these serve as defaults unless the legendentry gets its own value set
        # TODO: Fix
        preset_attrs = extractattributes(leg, LegendEntry)

        for (title, entries) in entry_groups

            if isnothing(title)
                # in case a group has no title
                push!(titletexts, nothing)
            else
                push!(titletexts, Label(scene, text = title, font = leg.titlefont, color = leg.titlecolor,
                    fontsize = leg.titlesize, halign = leg.titlehalign, valign = leg.titlevalign))
            end

            etexts = []
            erects = []
            eplots = []
            for (i, e) in enumerate(entries)
                # fill missing entry attributes with those carried by the legend
                merge!(e.attributes, preset_attrs)

                isnothing(e.label[]) && continue

                # create the label
                justification = map(leg.labeljustification, e.labelhalign) do lj, lha
                    return lj isa Automatic ? lha : lj
                end
                push!(etexts,
                      Label(scene; text=e.label, fontsize=e.labelsize, font=e.labelfont, justification=justification,
                            color=e.labelcolor, halign=e.labelhalign, valign=e.labelvalign))

                # create the patch rectangle
                rect = Box(scene; color=e.patchcolor, strokecolor=e.patchstrokecolor, strokewidth=e.patchstrokewidth,
                           width=lift(x -> x[1], blockscene, e.patchsize), height=lift(x -> x[2], blockscene, e.patchsize))
                push!(erects, rect)
                translate!(rect.blockscene, 0, 0, -5) # patches before background but behind legend elements (legend is at +10)

                # plot the symbols belonging to this entry
                symbolplots = AbstractPlot[]
                for element in e.elements
                    append!(symbolplots,
                            legendelement_plots!(scene, element, rect.layoutobservables.computedbbox, e.attributes))
                end

                push!(eplots, symbolplots)
            end
            push!(entrytexts, etexts)
            push!(entryrects, erects)
            push!(entryplots, eplots)
        end
        relayout()
    end


    # trigger suggestedbbox
    notify(leg.layoutobservables.suggestedbbox)

    setfield!(leg, :entrygroups, entry_groups)
    notify(entry_groups)

    return
end

function connect_block_layoutobservables!(leg::Legend, layout_width, layout_height, layout_tellwidth, layout_tellheight, layout_halign, layout_valign, layout_alignmode)
    connect!(layout_width, leg.width)
    connect!(layout_height, leg.height)
    # Legend has special logic for automatic tellwidth and tellheight
    connect!(layout_tellwidth, leg._tellwidth)
    connect!(layout_tellheight, leg._tellheight)

    connect!(layout_halign, leg.halign)
    connect!(layout_valign, leg.valign)
    connect!(layout_alignmode, leg.alignmode)
    return
end



function legendelement_plots!(scene, element::MarkerElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes
    fracpoints = attrs.markerpoints
    points = lift((bb, fp) -> fractionpoint.(Ref(bb), fp), scene, bbox, fracpoints)
    scat = scatter!(scene, points, color = attrs.markercolor, marker = attrs.marker,
        markersize = attrs.markersize,
        strokewidth = attrs.markerstrokewidth,
        strokecolor = attrs.markerstrokecolor, inspectable = false,
        colormap = attrs.markercolormap,
        colorrange = attrs.markercolorrange,
    )

    return [scat]
end

function legendelement_plots!(scene, element::LineElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.linepoints
    points = lift((bb, fp) -> fractionpoint.(Ref(bb), fp), scene, bbox, fracpoints)
    lin = lines!(scene, points, linewidth = attrs.linewidth, color = attrs.linecolor,
        colormap = attrs.linecolormap, colorrange = attrs.linecolorrange,
        linestyle = attrs.linestyle, inspectable = false)

    return [lin]
end

function legendelement_plots!(scene, element::PolyElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes
    fracpoints = attrs.polypoints
    points = lift((bb, fp) -> fractionpoint.(Ref(bb), fp), scene, bbox, fracpoints)
    pol = poly!(scene, points, strokewidth = attrs.polystrokewidth, color = attrs.polycolor,
        strokecolor = attrs.polystrokecolor, inspectable = false,
        colormap = attrs.polycolormap, colorrange = attrs.polycolorrange)

    return [pol]
end

function Base.getproperty(lentry::LegendEntry, s::Symbol)
    if s in fieldnames(LegendEntry)
        getfield(lentry, s)
    else
        lentry.attributes[s]
    end
end

function Base.setproperty!(lentry::LegendEntry, s::Symbol, value)
    if s in fieldnames(LegendEntry)
        setfield!(lentry, s, value)
    else
        lentry.attributes[s][] = value
    end
end

function Base.propertynames(lentry::LegendEntry)
    [fieldnames(T)..., keys(lentry.attributes)...]
end

legendelements(le::LegendElement, legend) = LegendElement[le]
legendelements(les::AbstractArray{<:LegendElement}, legend) = LegendElement[les...]


function LegendEntry(label, contentelements::AbstractArray, legend; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = vcat(legendelements.(contentelements, Ref(legend))...)
    LegendEntry(elems, attrs)
end

function LegendEntry(label, contentelement, legend; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = legendelements(contentelement, legend)
    if isempty(elems)
        error("`legendelements` returned an empty list for content element of type $(typeof(contentelement)). That could mean that neither this object nor any possible child objects had a method for `legendelements` defined that returned a non-empty result.")
    end
    LegendEntry(elems, attrs)
end


function LineElement(;kwargs...)
    _legendelement(LineElement, Attributes(kwargs))
end

function MarkerElement(;kwargs...)
    _legendelement(MarkerElement, Attributes(kwargs))
end

function PolyElement(;kwargs...)
    _legendelement(PolyElement, Attributes(kwargs))
end

function _legendelement(T::Type{<:LegendElement}, a::Attributes)
    _rename_attributes!(T, a)
    T(a)
end

_renaming_mapping(::Type{LineElement}) = Dict(
    :points => :linepoints,
    :color => :linecolor,
    :colormap => :linecolormap,
    :colorrange => :linecolorrange,
)
_renaming_mapping(::Type{MarkerElement}) = Dict(
    :points => :markerpoints,
    :color => :markercolor,
    :strokewidth => :markerstrokewidth,
    :strokecolor => :markerstrokecolor,
    :colormap => :markercolormap,
    :colorrange => :markercolorrange,
)
_renaming_mapping(::Type{PolyElement}) = Dict(
    :points => :polypoints,
    :color => :polycolor,
    :strokewidth => :polystrokewidth,
    :strokecolor => :polystrokecolor,
    :colormap => :polycolormap,
    :colorrange => :polycolorrange,
)

function _rename_attributes!(T, a)
    m = _renaming_mapping(T)
    for (key, val) in pairs(a)
        if haskey(m, key)
            newkey = m[key]
            if haskey(a, newkey)
                error("Can't rename $key to $newkey as $newkey already exists in attributes.")
            end
            a[newkey] = pop!(a, key)
        end
    end
    a
end

choose_scalar(attr, default) = is_scalar_attribute(to_value(attr)) ? attr : default

function extract_color(@nospecialize(plot), color_default)
    color = haskey(plot, :calculated_color) ? plot.calculated_color : plot.color
    color[] isa ColorMapping && return color_default
    return choose_scalar(color, color_default)
end

function legendelements(plot::Union{Lines, LineSegments}, legend)
    LegendElement[LineElement(
        color = extract_color(plot, legend[:linecolor]),
        linestyle = choose_scalar(plot.linestyle, legend[:linestyle]),
        linewidth = choose_scalar(plot.linewidth, legend[:linewidth]),
        colormap = plot.colormap,
        colorrange = plot.colorrange,
    )]
end

function legendelements(plot::Scatter, legend)
    LegendElement[MarkerElement(
        color = extract_color(plot, legend[:markercolor]),
        marker = choose_scalar(plot.marker, legend[:marker]),
        markersize = choose_scalar(plot.markersize, legend[:markersize]),
        strokewidth = choose_scalar(plot.strokewidth, legend[:markerstrokewidth]),
        strokecolor = choose_scalar(plot.strokecolor, legend[:markerstrokecolor]),
        colormap = plot.colormap,
        colorrange = plot.colorrange,
    )]
end

function legendelements(plot::Union{Poly, Violin, BoxPlot, CrossBar, Density}, legend)
    color = extract_color(plot, legend[:polycolor])
    LegendElement[PolyElement(
        color = color,
        strokecolor = choose_scalar(plot.strokecolor, legend[:polystrokecolor]),
        strokewidth = choose_scalar(plot.strokewidth, legend[:polystrokewidth]),
        colormap = plot.colormap,
        colorrange = plot.colorrange,
    )]
end

function legendelements(plot::Band, legend)
    # there seems to be no stroke for Band, so we set it invisible
    return LegendElement[PolyElement(;
        polycolor = choose_scalar(
            plot.color,
            legend[:polystrokecolor]
        ),
        polystrokecolor = :transparent,
        polystrokewidth = 0,
        polycolormap = plot.colormap,
        polycolorrange = plot.colorrange,
    )]
end

# if there is no specific overload available, we go through the child plots and just stack
# those together as a simple fallback
function legendelements(plot, legend)::Vector{LegendElement}
    reduce(vcat, [legendelements(childplot, legend) for childplot in plot.plots], init = [])
end

# Text has no meaningful legend, but it contains a linesegments for latex applications
# which can surface as a line in the final legend
function legendelements(plot::Text, legend)::Vector{LegendElement}
    []
end

function Base.getproperty(legendelement::T, s::Symbol) where T <: LegendElement
    if s in fieldnames(T)
        getfield(legendelement, s)
    else
        legendelement.attributes[s]
    end
end

function Base.setproperty!(legendelement::T, s::Symbol, value) where T <: LegendElement
    if s in fieldnames(T)
        setfield!(legendelement, s, value)
    else
        legendelement.attributes[s][] = value
    end
end

function Base.propertynames(legendelement::T) where T <: LegendElement
    [fieldnames(T)..., keys(legendelement.attributes)...]
end

function to_entry_group(legend_defaults, contents::AbstractVector, labels::AbstractVector, title=nothing)
    if length(contents) != length(labels)
        error("Number of elements not equal: $(length(contents)) content elements and $(length(labels)) labels.")
    end
    entries = [LegendEntry(label, content, legend_defaults) for (content, label) in zip(contents, labels)]
    return [(title, entries)]
end

function to_entry_group(
        legend_defaults, contentgroups::AbstractVector{<:AbstractVector},
        labelgroups::AbstractVector{<:AbstractVector}, titles::AbstractVector)
    if !(length(titles) == length(contentgroups) == length(labelgroups))
        error("Number of elements not equal: $(length(titles)) titles, $(length(contentgroups)) content groups and $(length(labelgroups)) label groups.")
    end
    entries = [[LegendEntry(l, pg, legend_defaults) for (l, pg) in zip(labelgroup, contentgroup)]
        for (labelgroup, contentgroup) in zip(labelgroups, contentgroups)]
    return [(t, en) for (t, en) in zip(titles, entries)]
end

"""
    Legend(
        fig_or_scene,
        contents::AbstractArray,
        labels::AbstractArray,
        title = nothing;
        kwargs...)

Create a legend from `contents` and `labels` where each label is associated to
one content element. A content element can be an `AbstractPlot`, an array of
`AbstractPlots`, a `LegendElement`, or any other object for which the
`legendelements` method is defined.
"""
function Legend(fig_or_scene,
        contents::AbstractVector,
        labels::AbstractVector,
        title = nothing;
                bbox=nothing, kwargs...)

    scene = get_topscene(fig_or_scene)
    legend_defaults = block_defaults(:Legend, Dict{Symbol, Any}(kwargs), scene)
    entry_groups = to_entry_group(Attributes(legend_defaults), contents, labels, title)
    entrygroups = Observable(entry_groups)
    legend_defaults[:entrygroups] = entrygroups
    # Use low-level constructor to not calculate legend_defaults a second time
    return _block(Legend, fig_or_scene, (), legend_defaults, bbox; kwdict_complete=true)
end



"""
    Legend(
        fig_or_scene,
        contentgroups::AbstractVector{<:AbstractVector},
        labelgroups::AbstractVector{<:AbstractVector},
        titles::AbstractVector;
        kwargs...)

Create a multi-group legend from `contentgroups`, `labelgroups` and `titles`.
Each group from `contentgroups` and `labelgroups` is associated with one title
from `titles` (a title can be `nothing` to hide it).

Within each group, each content element is associated with one label. A content
element can be an `AbstractPlot`, an array of `AbstractPlots`, a `LegendElement`,
or any other object for which the `legendelements` method is defined.
"""
function Legend(fig_or_scene,
        contentgroups::AbstractVector{<:AbstractVector},
        labelgroups::AbstractVector{<:AbstractVector},
        titles::AbstractVector;
        bbox=nothing, kwargs...)

    scene = get_scene(fig_or_scene)
    legend_defaults = block_defaults(:Legend, Dict{Symbol,Any}(kwargs), scene)
    entry_groups = to_entry_group(legend_defaults, contentgroups, labelgroups, titles)
    entrygroups = Observable(entry_groups)
    legend_defaults[:entrygroups] = entrygroups
    return _block(Legend, fig_or_scene, (), legend_defaults, bbox; kwdict_complete=true)
end


"""
    Legend(fig_or_scene, axis::Union{Axis, Scene, LScene}, title = nothing; merge = false, unique = false, kwargs...)

Create a single-group legend with all plots from `axis` that have the
attribute `label` set.

If `merge` is `true`, all plot objects with the same label will be layered on top of each other into one legend entry.
If `unique` is `true`, all plot objects with the same plot type and label will be reduced to one occurrence.
"""
function Legend(fig_or_scene, axis::Union{Axis, Axis3, Scene, LScene}, title = nothing; merge = false, unique = false, kwargs...)
    plots, labels = get_labeled_plots(axis, merge = merge, unique = unique)
    isempty(plots) && error("There are no plots with labels in the given axis that can be put in the legend. Supply labels to plotting functions like `plot(args...; label = \"My label\")`")
    Legend(fig_or_scene, plots, labels, title; kwargs...)
end

function get_labeled_plots(ax; merge::Bool, unique::Bool)
    lplots = filter(get_plots(ax)) do plot
        haskey(plot.attributes, :label)
    end
    labels = map(lplots) do l
        l.label[]
    end

    # filter out plots with same plot type and label
    if unique
        plots_labels = Base.unique(((p, l),) -> (typeof(p), l), zip(lplots, labels))
        lplots = first.(plots_labels)
        labels = last.(plots_labels)
    end

    if merge
        ulabels = Base.unique(labels)
        mergedplots = [[lp for (i, lp) in enumerate(lplots) if labels[i] == ul]
            for ul in ulabels]

        lplots, labels = mergedplots, ulabels
    end

    lplots, labels
end

get_plots(p::AbstractPlot) = [p]
get_plots(ax::Union{Axis, Axis3}) = get_plots(ax.scene)
get_plots(lscene::LScene) = get_plots(lscene.scene)
function get_plots(scene::Scene)
    plots = AbstractPlot[]
    for p in scene.plots
        append!(plots, get_plots(p))
    end
    return plots
end

# convenience constructor for axis legend
axislegend(ax = current_axis(); kwargs...) = axislegend(ax, ax; kwargs...)

axislegend(title::AbstractString; kwargs...) = axislegend(current_axis(), current_axis(), title; kwargs...)
axislegend(ax, title::AbstractString; kwargs...) = axislegend(ax, ax, title; kwargs...)

"""
    axislegend(ax, args...; position = :rt, kwargs...)
    axislegend(ax, args...; position = (1, 1), kwargs...)
    axislegend(ax = current_axis(); kwargs...)
    axislegend(title::AbstractString; kwargs...)
    axislegend(ax, title::AbstractString; kwargs...)

Create a legend that sits inside an Axis's plot area.

The position can be a Symbol where the first letter controls the horizontal
alignment and can be l, r or c, and the second letter controls the vertical
alignment and can be t, b or c. Or it can be a tuple where the first
element is set as the Legend's halign and the second element as its valign.

With the keywords merge and unique you can control how plot objects with the
same labels are treated. If merge is true, all plot objects with the same
label will be layered on top of each other into one legend entry. If unique
is true, all plot objects with the same plot type and label will be reduced
to one occurrence.
"""
function axislegend(ax, args...; position = :rt, kwargs...)
    Legend(ax.parent, args...;
        bbox = ax.scene.viewport,
        margin = (6, 6, 6, 6),
        legend_position_to_aligns(position)...,
        kwargs...)
end

function legend_position_to_aligns(s::Symbol)
    p = string(s)
    length(p) != 2 && throw(ArgumentError("Position symbol must have length == 2"))

    haligns = Dict(
        'l' => :left,
        'r' => :right,
        'c' => :center,
    )
    haskey(haligns, p[1]) || throw(ArgumentError("First letter can be l, r or c, not $(p[1])."))

    valigns = Dict(
        't' => :top,
        'b' => :bottom,
        'c' => :center,
    )
    haskey(valigns, p[2]) || throw(ArgumentError("Second letter can be b, t or c, not $(p[2])."))

    (halign = haligns[p[1]], valign = valigns[p[2]])
end

function legend_position_to_aligns(t::Tuple{Any, Any})
    (halign = t[1], valign = t[2])
end

function attribute_examples(::Type{Legend})
    Dict(
        :colgap => [
            Example(
                name = "Column gaps",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[1, 2], ax, "Default", nbanks = 2)
                    Legend(fig[1, 3], ax, "colgap = 40", nbanks = 2, colgap = 40)
                    fig
                    """
            )
        ],
        :groupgap => [
            Example(
                name = "Group gaps",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lin = lines!(ax, 1:10, linestyle = :dash)
                    pol = poly!(ax, [(5, 0), (10, 0), (7.5, 5)])
                    sca = scatter!(ax, 4:13)
                    Legend(fig[1, 2],
                        [[lin], [pol], [sca]],
                        [["Line"], ["Poly"], ["Scatter"]],
                        ["Default", "Group 2", "Group 3"];

                    )
                    Legend(fig[1, 3],
                        [[lin], [pol], [sca]],
                        [["Line"], ["Poly"], ["Scatter"]],
                        ["groupgap = 30", "Group 2", "Group 3"];
                        groupgap = 30,
                    )
                    fig
                    """
            )
        ],
        :patchsize => [
            Example(
                name = "Patch size",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[1, 2], ax, "Default")
                    Legend(fig[1, 3], ax, "(40, 20)", patchsize = (40, 20))
                    fig
                    """
            )
        ],
        :patchlabelgap => [
            Example(
                name = "Gap sizes",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[1, 2], ax, "Default")
                    Legend(fig[1, 3], ax, "patchlabelgap\n= 20", patchlabelgap = 20)
                    fig
                    """
            )
        ],
        :orientation => [
            Example(
                name = "Orientations",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[2, 1], ax, "orientation\n= :horizontal", orientation = :horizontal)
                    Legend(fig[1, 2], ax, "orientation\n= :vertical", orientation = :vertical)
                    fig
                    """
            )
        ],
        :nbanks => [
            Example(
                name = "Number of banks with `orientation = :vertical`",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    grid = GridLayout(fig[1, 2], tellheight = false)
                    Legend(grid[1, 1], ax, "nbanks = 1", nbanks = 1, tellheight = true)
                    Legend(grid[1, 2], ax, "nbanks = 2", nbanks = 2, tellheight = true)
                    Legend(grid[2, :], ax, "nbanks = 3", nbanks = 3, tellheight = true)
                    fig
                    """
            ),
            Example(
                name = "Number of banks with `orientation = :horizontal`",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    grid = GridLayout(fig[2, 1], tellwidth = false)
                    Legend(grid[1, 1], ax, "nbanks = 1", nbanks = 1,
                        orientation = :horizontal, tellwidth = true)
                    Legend(grid[2, 1], ax, "nbanks = 2", nbanks = 2,
                        orientation = :horizontal, tellwidth = true)
                    Legend(grid[:, 2], ax, "nbanks = 3", nbanks = 3,
                        orientation = :horizontal, tellwidth = true)
                    fig
                    """
            ),
        ],
        :titleposition => [
            Example(
                name = "Title positions",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[1, 2], ax, "titleposition\n= :top", titleposition = :top)
                    Legend(fig[1, 3], ax, "titleposition\n= :left", titleposition = :left)
                    fig
                    """
            ),
        ],
        :rowgap => [
            Example(
                name = "Row gaps",
                code = """
                    fig = Figure()
                    ax = Axis(fig[1, 1])
                    lines!(ax, 1:10, linestyle = :dash, label = "Line")
                    poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
                    scatter!(ax, 4:13, label = "Scatter")
                    Legend(fig[1, 2], ax, "Default")
                    Legend(fig[1, 3], ax, "rowgap = 10", rowgap = 10)
                    fig
                    """
            ),
        ],
    )
end
