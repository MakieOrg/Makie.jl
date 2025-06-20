function get_n_visible(entry::LegendEntry)
    n_visible = Ref(0)
    n_total = Ref(0)
    foreach_plot(entry) do p
        n_visible[] += Int64(p.visible[])
        n_total[] += 1
    end
    return n_visible[], n_total[]
end

function _toggle_hovered_legend_visibilities!(mpos, entry_groups, entryshades)
    for ((title, entries), shades) in zip(entry_groups, entryshades)
        for (entry, shade) in zip(entries, shades)
            # shade and halfshade are Box()es covering the entry
            if mpos in shade.layoutobservables.computedbbox[]
                # determine number of currently visible plot elements
                n_visible, n_total = get_n_visible(entry)
                n_total == 0 && return
                # if not all attached plots have the same state we set all to visible
                sync_to_visible = n_visible != n_total
                toggle_visibility!(entry, sync_to_visible)
                return
            end
        end
    end
    return
end

function _toggle_all_legend_visibilities_synchronized!(entry_groups)
    sync_to_visible = false
    for (_, entries) in entry_groups, e in entries
        n_visible, n_total = get_n_visible(e)
        sync_to_visible |= n_visible != n_total
        sync_to_visible && break
    end
    for (_, entries) in entry_groups, e in entries
        toggle_visibility!(e, sync_to_visible)
    end
    return
end

function initialize_block!(leg::Legend; entrygroups)
    entry_groups = convert(Observable{Vector{Tuple{Any, Vector{LegendEntry}}}}, entrygroups)
    blockscene = leg.blockscene

    # by default, `tellwidth = true` and `tellheight = false` for vertical legends
    # and vice versa for horizontal legends
    real_tellwidth = @lift $(leg.tellwidth) === automatic ? $(leg.orientation) === :vertical : $(leg.tellwidth)
    real_tellheight = @lift $(leg.tellheight) === automatic ? $(leg.orientation) === :horizontal : $(leg.tellheight)
    setfield!(leg, :_tellheight, real_tellheight)
    setfield!(leg, :_tellwidth, real_tellwidth)

    legend_area = lift(round_to_IRect2D, blockscene, leg.layoutobservables.computedbbox)

    scene = Scene(blockscene, blockscene.viewport, camera = campixel!)
    leg.scene = scene
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

    bg = poly!(
        scene,
        legendrect,
        color = backgroundcolor, strokewidth = leg.framewidth, visible = leg.framevisible,
        strokecolor = leg.framecolor, inspectable = false
    )
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
    entryshades = [Box[]]
    entryhalfshades = [Box[]]

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
            eshades = entryshades[g]
            ehalfshades = entryhalfshades[g]

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
                    isnothing(title) || (grid[1, 2g - 1] = title)
                    grid[1, 2g] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                elseif leg.titleposition[] === :top
                    isnothing(title) || (grid[1, g] = title)
                    grid[2, g] = GridLayout(halign = leg.gridshalign[], valign = leg.gridsvalign[])
                end
            end

            for (n, (et, er, es, ehs)) in enumerate(zip(etexts, erects, eshades, ehalfshades))
                i, j = leg.orientation[] === :vertical ? rowcol(n) : reverse(rowcol(n))
                subgl[i, 2j - 1] = er
                subgl[i, 2j] = et
                subgl[i, (2j - 1):2j] = es
                subgl[i, (2j - 1):2j] = ehs
            end

            rowgap!(subgl, leg.rowgap[])
            for c in 1:(ncols(subgl) - 1)
                colgap!(subgl, c, c % 2 == 1 ? leg.patchlabelgap[] : leg.colgap[])
            end
        end

        for r in 1:(nrows(grid) - 1)
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
        for c in 1:(ncols(grid) - 1)
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

    onany(
        blockscene, leg.nbanks, leg.titleposition, leg.rowgap, leg.colgap, leg.patchlabelgap, leg.groupgap,
        leg.titlegap,
        leg.titlevisible, leg.orientation, leg.gridshalign, leg.gridsvalign
    ) do args...
        relayout()
        return
    end

    shade_color = RGBAf(0.9, 0.9, 0.9, 0.65)
    hatch_width = leg.labelsize[]
    halfshade_color = LinePattern(
        direction = Vec2f(1), width = hatch_width / 2,
        tilesize = round.(Int, (hatch_width, hatch_width)), linecolor = shade_color
    )

    # For cleaning up visible listeners on relayouting
    entry_observer_funcs = ObserverFunction[]

    on(blockscene, entry_groups) do entry_groups
        # first delete all existing labels and patches

        for t in titletexts
            !isnothing(t) && delete!(t)
        end
        empty!(titletexts)

        foreach(texts -> foreach(delete!, texts), entrytexts)
        empty!(entrytexts)

        foreach(rects -> foreach(delete!, rects), entryrects)
        empty!(entryrects)

        # delete patch plots
        for eplotgroup in entryplots
            for eplots in eplotgroup
                # each entry can have a vector of patch plots
                delete!.(scene, eplots)
            end
        end
        empty!(entryplots)

        foreach(shade_rects -> foreach(delete!, shade_rects), entryshades)
        empty!(entryshades)
        foreach(halfshade_rects -> foreach(delete!, halfshade_rects), entryhalfshades)
        empty!(entryhalfshades)

        foreach(off, entry_observer_funcs)
        empty!(entry_observer_funcs)

        # the attributes for legend entries that the legend itself carries
        # these serve as defaults unless the legendentry gets its own value set
        # TODO: Fix
        preset_attrs = extractattributes(leg, LegendEntry)

        for (title, entries) in entry_groups

            if isnothing(title)
                # in case a group has no title
                push!(titletexts, nothing)
            else
                push!(
                    titletexts, Label(
                        scene, text = title, font = leg.titlefont, color = leg.titlecolor,
                        fontsize = leg.titlesize, halign = leg.titlehalign, valign = leg.titlevalign
                    )
                )
            end

            # e for entry
            etexts = []
            erects = []
            eplots = []
            eshades = []
            ehalfshades = []

            for (i, entry) in enumerate(entries)

                # fill missing entry attributes with those carried by the legend
                merge!(entry.attributes, preset_attrs)

                isnothing(entry.label[]) && continue

                # create the label
                justification = map(leg.labeljustification, entry.labelhalign) do lj, lha
                    return lj isa Automatic ? lha : lj
                end
                push!(
                    etexts,
                    Label(
                        scene; text = entry.label, fontsize = entry.labelsize,
                        font = entry.labelfont, justification = justification,
                        color = entry.labelcolor,
                        halign = entry.labelhalign, valign = entry.labelvalign
                    )
                )

                # create the patch rectangle
                rect = Box(
                    scene; color = entry.patchcolor,
                    strokecolor = entry.patchstrokecolor, strokewidth = entry.patchstrokewidth,
                    width = lift(x -> x[1], blockscene, entry.patchsize),
                    height = lift(x -> x[2], blockscene, entry.patchsize)
                )
                push!(erects, rect)
                translate!(rect.blockscene, 0, 0, -5) # patches before background but behind legend elements (legend is at +10)

                # plot the symbols belonging to this entry
                symbolplots = AbstractPlot[]
                for element in entry.elements
                    append!(
                        symbolplots,
                        legendelement_plots!(scene, element, rect.layoutobservables.computedbbox, entry.attributes)
                    )
                end
                push!(eplots, symbolplots)

                # TODO: Should this be connected to scene/blockscene for cleanup?
                # Probably not plots since plot deletion needs to trigger relayout anyway

                # listen to visibility attributes of plot elements to toggle shades below
                visibilities = get_plot_visibilities(entry)
                shade_visible = Observable{Bool}(false)
                halfshade_visible = Observable{Bool}(false)
                obsfunc = onany(visibilities...) do vis...
                    mode = shade_visible_mode(vis)
                    shade_vis = mode === :show
                    shade_visible[] != shade_vis && (shade_visible[] = shade_vis)
                    halfshade_vis = mode === :halfshow
                    halfshade_visible[] != halfshade_vis && (halfshade_visible[] = halfshade_vis)
                    return
                end
                append!(entry_observer_funcs, obsfunc)

                # create a shade on top of label and marker to indicate hidden plots (base scene is at +10)
                shade = Box(scene; color = shade_color, visible = shade_visible, strokewidth = 0, z = 9_990)
                push!(eshades, shade)
                halfshade = Box(scene; color = halfshade_color, visible = halfshade_visible, strokewidth = 0, z = 9_990)
                push!(ehalfshades, halfshade)
            end

            push!(entrytexts, etexts)
            push!(entryrects, erects)
            push!(entryplots, eplots)
            push!(entryshades, eshades)
            push!(entryhalfshades, ehalfshades)
        end

        relayout()
    end

    # Process hide/show events
    sevents = events(blockscene)
    on(scene, sevents.mousebutton, priority = 1) do event
        mpos = sevents.mouseposition[]
        if (event.action == Mouse.release) && in(mpos, legend_area[])
            if event.button == Mouse.left
                # Find hovered entry and toggle visibility for all connected plots
                _toggle_hovered_legend_visibilities!(mpos, entry_groups[], entryshades)
            elseif event.button == Mouse.right
                # Toggle all connected plot visibilities without synchronization
                for (_, entries) in entry_groups[], e in entries
                    toggle_visibility!(e)
                end
            elseif event.button == Mouse.middle
                # Synchronized toggle of all connected plot visibilities
                # (if they differ synchronize all to true, otherwise toggle)
                _toggle_all_legend_visibilities_synchronized!(entry_groups[])
            else
                return Consume(false)
            end
            return Consume(true)
        end
        return Consume(false)
    end

    # trigger suggestedbbox
    notify(leg.layoutobservables.suggestedbbox)

    setfield!(leg, :entrygroups, entry_groups)
    notify(entry_groups)

    return
end

struct LegendOverride
    overrides::Attributes
    LegendOverride(attrs::Attributes) = new(attrs)
    LegendOverride(l::LegendOverride) = l
    LegendOverride(attrs) = new(Attributes(attrs))
end

LegendOverride(; kwargs...) = LegendOverride(Attributes(; kwargs...))

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
    scat = scatter!(
        scene, points, color = attrs.markercolor, marker = attrs.marker,
        markersize = attrs.markersize,
        strokewidth = attrs.markerstrokewidth,
        strokecolor = attrs.markerstrokecolor, inspectable = false,
        colormap = attrs.markercolormap,
        colorrange = attrs.markercolorrange,
        alpha = attrs.alpha,
    )

    return [scat]
end

function legendelement_plots!(scene, element::LineElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes

    fracpoints = attrs.linepoints
    points = lift((bb, fp) -> fractionpoint.(Ref(bb), fp), scene, bbox, fracpoints)
    lin = lines!(
        scene, points, linewidth = attrs.linewidth, color = attrs.linecolor,
        colormap = attrs.linecolormap, colorrange = attrs.linecolorrange,
        linestyle = attrs.linestyle, inspectable = false, alpha = attrs.alpha
    )

    return [lin]
end

function legendelement_plots!(scene, element::PolyElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attrs = element.attributes
    fracpoints = attrs.polypoints
    points = lift((bb, fp) -> fractionpoint.(Ref(bb), fp), scene, bbox, fracpoints)
    pol = poly!(
        scene, points, strokewidth = attrs.polystrokewidth, color = attrs.polycolor,
        strokecolor = attrs.polystrokecolor, inspectable = false,
        colormap = attrs.polycolormap, colorrange = attrs.polycolorrange,
        linestyle = attrs.linestyle, alpha = attrs.alpha
    )

    return [pol]
end

function legendelement_plots!(scene, element::ImageElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attr = element.attributes
    lims = map(scene, bbox, attr.limits) do bb, lims
        x0, y0 = minimum(bb)
        w, h = widths(bb)
        xl0, xl1 = extrema(lims[1])
        yl0, yl1 = extrema(lims[2])
        return x0 + w * xl0 .. x0 + w * xl1, y0 + h * yl0 .. y0 + h * yl1
    end
    plt = image!(
        scene, map(first, scene, lims), map(last, scene, lims),
        attr.data, colormap = attr.colormap, colorrange = attr.colorrange,
        inspectable = false, alpha = attr.alpha, interpolate = attr.interpolate
    )

    return [plt]
end

function legendelement_plots!(scene, element::MeshScatterElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attr = element.attributes
    plt = meshscatter!(
        scene, attr.position,
        marker = attr.marker, markersize = attr.markersize, rotation = attr.rotation,
        colormap = attr.colormap, colorrange = attr.colorrange,
        color = attr.color, alpha = attr.alpha,
        inspectable = false
    )

    # from Makie.decompose_translation_scale_rotation_matrix(Makie.lookat_basis(Vec3f(1), Vec3f(0), Vec3f(0,0,1)))
    rot = Quaternionf(- 0.17591983, - 0.42470822, - 0.82047325, 0.33985117)
    rotate!(plt, rot)

    on(scene, bbox, update = true) do bb
        c = to_ndim(Point3f, minimum(bb) .+ 0.5 .* widths(bb), 0)
        ws = Vec3f(0.5 * minimum(widths(bb)))
        translate!(plt, c)
        scale!(plt, ws)
        return
    end

    return [plt]
end

function legendelement_plots!(scene, element::MeshElement, bbox::Observable{Rect2f}, defaultattrs::Attributes)
    merge!(element.attributes, defaultattrs)
    attr = element.attributes
    plt = mesh!(
        scene, attr.mesh,
        colormap = attr.colormap, colorrange = attr.colorrange,
        color = attr.color, alpha = attr.alpha,
        inspectable = false, uv_transform = attr.uv_transform
    )

    # from Makie.decompose_translation_scale_rotation_matrix(Makie.lookat_basis(Vec3f(1), Vec3f(0), Vec3f(0,0,1)))
    rot = Quaternionf(- 0.17591983, - 0.42470822, - 0.82047325, 0.33985117)
    rotate!(plt, rot)

    on(scene, bbox, update = true) do bb
        c = to_ndim(Point3f, minimum(bb) .+ 0.5 .* widths(bb), 0)
        ws = Vec3f(0.5 * minimum(widths(bb)))
        translate!(plt, c)
        scale!(plt, ws)
        return
    end

    return [plt]
end

function Base.getproperty(lentry::LegendEntry, s::Symbol)
    return if s in fieldnames(LegendEntry)
        getfield(lentry, s)
    else
        lentry.attributes[s]
    end
end

function Base.setproperty!(lentry::LegendEntry, s::Symbol, value)
    return if s in fieldnames(LegendEntry)
        setfield!(lentry, s, value)
    else
        lentry.attributes[s][] = value
    end
end

function Base.propertynames(lentry::LegendEntry)
    return (fieldnames(LegendEntry)..., keys(lentry.attributes)...)
end

legendelements(le::LegendElement, legend) = LegendElement[le]
legendelements(les::AbstractArray{<:LegendElement}, legend) = LegendElement[les...]

legendelements(p::Pair, legend) = legendelements(p[1], legend, LegendOverride(p[2]))

function legendelements(any, legend, override::LegendOverride)
    les = legendelements(any, legend)
    for le in les
        apply_legend_override!(le, override)
    end
    return les
end

function apply_legend_override!(le::MarkerElement, override::LegendOverride)
    renamed_attrs = _rename_attributes!(MarkerElement, copy(override.overrides))
    for sym in (:markerpoints, :markersize, :markercolor, :markerstrokewidth, :markerstrokecolor, :markercolormap, :markercolorrange, :alpha)
        if haskey(renamed_attrs, sym)
            le.attributes[sym] = renamed_attrs[sym]
        end
    end
    return
end

function apply_legend_override!(le::LineElement, override::LegendOverride)
    renamed_attrs = _rename_attributes!(LineElement, copy(override.overrides))
    for sym in (:linepoints, :linewidth, :linecolor, :linecolormap, :linecolorrange, :linestyle, :alpha)
        if haskey(renamed_attrs, sym)
            le.attributes[sym] = renamed_attrs[sym]
        end
    end
    return
end

function apply_legend_override!(le::PolyElement, override::LegendOverride)
    renamed_attrs = _rename_attributes!(PolyElement, copy(override.overrides))
    for sym in (:polypoints, :polycolor, :polystrokewidth, :polystrokecolor, :polycolormap, :polycolorrange, :polystrokestyle, :alpha)
        if haskey(renamed_attrs, sym)
            le.attributes[sym] = renamed_attrs[sym]
        end
    end
    return
end

function apply_legend_override!(le::T, override::LegendOverride) where {T <: LegendElement}
    old2new = _renaming_mapping(T)

    for (k, v) in override.overrides
        if haskey(old2new, k)
            key = old2new[k]
            @assert !haskey(override.overrides, key) "Key $key with alias $k doubly defined."
        else
            key = k
        end

        if haskey(le.attributes, key)
            le.attributes[key] = v
        end
    end
    return
end

function LegendEntry(label, contentelement, override::Attributes, legend; kwargs...)
    attrs = Attributes(; label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    elems = legendelements(contentelement, legend, override)
    if isempty(elems)
        error("`legendelements` returned an empty list for content element of type $(typeof(contentelement)). That could mean that neither this object nor any possible child objects had a method for `legendelements` defined that returned a non-empty result.")
    end
    return LegendEntry(elems, attrs)
end


function LegendEntry(label, content, legend; kwargs...)
    attrs = Attributes(label = label)

    kwargattrs = Attributes(kwargs)
    merge!(attrs, kwargattrs)

    if content isa AbstractArray
        elems = vcat(legendelements.(content, Ref(legend))...)
    elseif content isa Pair
        if content[1] isa AbstractArray
            elems = vcat(legendelements.(content[1] .=> Ref(content[2]), Ref(legend))...)
        else
            elems = legendelements(content, legend)
        end
    else
        elems = legendelements(content, legend)
    end
    return LegendEntry(elems, attrs)
end

function LineElement(; plots = Plot[], kwargs...)
    return _legendelement(LineElement, plots, Attributes(kwargs))
end

function MarkerElement(; plots = Plot[], kwargs...)
    return _legendelement(MarkerElement, plots, Attributes(kwargs))
end

function PolyElement(; plots = Plot[], kwargs...)
    return _legendelement(PolyElement, plots, Attributes(kwargs))
end

ImageElement(; plots = Plot[], kwargs...) = _legendelement(ImageElement, plots, Attributes(kwargs))
MeshScatterElement(; plots = Plot[], kwargs...) = _legendelement(MeshScatterElement, plots, Attributes(kwargs))
MeshElement(; plots = Plot[], kwargs...) = _legendelement(MeshElement, plots, Attributes(kwargs))

function _legendelement(T::Type{<:LegendElement}, plot, a::Attributes)
    if !(plot isa AbstractVector{Plot} || plot isa Plot)
        error("plot needs to be a Plot or a Vector of Plots. `Plot[]` is allowed as well. Found: $(typeof(plot))")
    end
    ps = plot isa AbstractVector ? plot : [plot]
    _rename_attributes!(T, a)
    return T(ps, a)
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
_renaming_mapping(::Type{MeshElement}) = Dict()
_renaming_mapping(::Type{ImageElement}) = Dict()
_renaming_mapping(::Type{MeshScatterElement}) = Dict()

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
    return a
end

choose_scalar(attr, default) = is_scalar_attribute(to_value(attr)) ? attr : default

function extract_color(@nospecialize(plot), color_default)
    color = haskey(plot, :calculated_color) ? plot.calculated_color : plot.color
    color[] isa ColorMapping && return color_default
    return choose_scalar(color, color_default)
end

function legendelements(plot::Union{Lines, LineSegments}, legend)
    ls = plot.linestyle[]
    return LegendElement[
        LineElement(
            plots = plot,
            color = extract_color(plot, legend[:linecolor]),
            linestyle = choose_scalar(ls isa Vector ? Linestyle(ls) : ls, legend[:linestyle]),
            linewidth = choose_scalar(plot.linewidth, legend[:linewidth]),
            colormap = plot.colormap,
            colorrange = plot.colorrange,
            alpha = plot.alpha
        ),
    ]
end

function legendelements(plot::Scatter, legend)
    return LegendElement[
        MarkerElement(
            plots = plot,
            color = extract_color(plot, legend[:markercolor]),
            marker = choose_scalar(plot.marker, legend[:marker]),
            markersize = choose_scalar(plot.markersize, legend[:markersize]),
            strokewidth = choose_scalar(plot.strokewidth, legend[:markerstrokewidth]),
            strokecolor = choose_scalar(plot.strokecolor, legend[:markerstrokecolor]),
            colormap = plot.colormap,
            colorrange = plot.colorrange,
            alpha = plot.alpha,
        ),
    ]
end

function legendelements(plot::Union{Violin, BoxPlot, CrossBar}, legend)
    color = extract_color(plot, legend[:polycolor])
    return LegendElement[
        PolyElement(
            plots = plot,
            color = color,
            strokecolor = choose_scalar(plot.strokecolor, legend[:polystrokecolor]),
            strokewidth = choose_scalar(plot.strokewidth, legend[:polystrokewidth]),
            colormap = get(plot, :colormap, :viridis),
            colorrange = get(plot, :colorrange, automatic),
            alpha = get(plot, :alpha, 1.0f0),
        ),
    ]
end

function legendelements(plot::Band, legend)
    # there seems to be no stroke for Band, so we set it invisible
    return LegendElement[
        PolyElement(;
            plots = plot,
            polycolor = choose_scalar(
                plot.color,
                legend[:polystrokecolor]
            ),
            polystrokecolor = :transparent,
            polystrokewidth = 0,
            polycolormap = plot.colormap,
            polycolorrange = plot.colorrange,
            alpha = plot.alpha,
        ),
    ]
end

function legendelements(plot::Union{Poly, Density}, legend)
    color = Makie.extract_color(plot, legend[:polycolor])
    return LegendElement[
        Makie.PolyElement(
            plots = plot,
            color = color,
            strokecolor = Makie.choose_scalar(plot.strokecolor, legend[:polystrokecolor]),
            strokewidth = Makie.choose_scalar(plot.strokewidth, legend[:polystrokewidth]),
            colormap = plot.colormap,
            colorrange = plot.colorrange,
            linestyle = plot.linestyle,
            alpha = get(plot, :alpha, 1.0f0)
        ),
    ]
end

function legendelements(plot::Mesh, legend)
    return LegendElement[
        MeshElement(
            plots = plot,
            mesh = legend[:mesh],
            color = legend[:meshcolor],
            alpha = plot.alpha,
            colormap = plot.colormap,
            colorrange = plot.colorrange,
            uv_transform = automatic,
        ),
    ]
end

function legendelements(plot::Surface, legend)
    # TODO these where observables, but actually not any
    # Which can be updated from the Legend/user
    # So seems silly to convert them to observables
    data = to_value(legend.surfacedata)
    xyzs = convert_arguments(Surface, data...)
    mesh = surface2mesh(xyzs...)
    vals = legend.surfacevalues
    color = vals === automatic ? xyzs[end] : vals
    return LegendElement[
        MeshElement(
            plots = plot,
            mesh = mesh,
            color = color,
            colormap = plot.colormap,
            colorrange = legend[:surfacecolorrange],
            alpha = plot.alpha,
            uv_transform = identity, # otherwise color values don't line up with mesh
        ),
    ]
end


function legendelements(plot::Image, legend)
    return LegendElement[
        ImageElement(
            plots = plot,
            limits = legend[:imagelimits],
            data = legend[:imagevalues],
            colormap = plot.colormap,
            colorrange = legend.imagecolorrange,
            interpolate = true
        ),
    ]
end

function legendelements(plot::Heatmap, legend)
    return LegendElement[
        ImageElement(
            plots = plot,
            limits = legend[:heatmaplimits],
            data = legend[:heatmapvalues],
            colormap = plot.colormap,
            colorrange = legend.heatmapcolorrange,
            interpolate = false
        ),
    ]
end

function legendelements(plot::MeshScatter, legend)
    return LegendElement[
        MeshScatterElement(
            plots = plot,
            position = legend.meshscatterpoints,
            color = extract_color(plot, legend[:meshscattercolor]),
            marker = legend[:meshscattermarker],
            markersize = legend[:meshscattersize],
            rotation = legend[:meshscatterrotation],
            colormap = plot.colormap,
            colorrange = plot.colorrange,
            alpha = plot.alpha,
        ),
    ]
end


# if there is no specific overload available, we go through the child plots and just stack
# those together as a simple fallback
function legendelements(plot, legend)::Vector{LegendElement}
    return reduce(vcat, [legendelements(childplot, legend) for childplot in plot.plots], init = [])
end

# Text has no meaningful legend, but it contains a linesegments for latex applications
# which can surface as a line in the final legend
function legendelements(plot::Text, legend)::Vector{LegendElement}
    return []
end

function Base.getproperty(legendelement::T, s::Symbol) where {T <: LegendElement}
    return if s in fieldnames(T)
        getfield(legendelement, s)
    else
        legendelement.attributes[s]
    end
end

function Base.setproperty!(legendelement::T, s::Symbol, value) where {T <: LegendElement}
    return if s in fieldnames(T)
        setfield!(legendelement, s, value)
    else
        legendelement.attributes[s][] = value
    end
end

function Base.propertynames(legendelement::T) where {T <: LegendElement}
    return [fieldnames(T)..., keys(legendelement.attributes)...]
end

function to_entry_group(legend_defaults, contents::AbstractVector, labels::AbstractVector, title = nothing)
    if length(contents) != length(labels)
        error("Number of elements not equal: $(length(contents)) content elements and $(length(labels)) labels.")
    end
    entries = [LegendEntry(label, content, legend_defaults) for (content, label) in zip(contents, labels)]
    return [(title, entries)]
end

function to_entry_group(
        legend_defaults, contentgroups::AbstractVector{<:AbstractVector},
        labelgroups::AbstractVector{<:AbstractVector}, titles::AbstractVector
    )
    if !(length(titles) == length(contentgroups) == length(labelgroups))
        error("Number of elements not equal: $(length(titles)) titles, $(length(contentgroups)) content groups and $(length(labelgroups)) label groups.")
    end
    entries = [
        [LegendEntry(l, pg, legend_defaults) for (l, pg) in zip(labelgroup, contentgroup)]
            for (labelgroup, contentgroup) in zip(labelgroups, contentgroups)
    ]
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
function Legend(
        fig_or_scene,
        contents::AbstractVector,
        labels::AbstractVector,
        title = nothing;
        bbox = nothing, kwargs...
    )

    scene = get_topscene(fig_or_scene)
    legend_defaults = block_defaults(:Legend, Dict{Symbol, Any}(kwargs), scene)
    entry_groups = to_entry_group(Attributes(legend_defaults), contents, labels, title)
    entrygroups = Observable(entry_groups)
    legend_defaults[:entrygroups] = entrygroups
    # Use low-level constructor to not calculate legend_defaults a second time
    return _block(Legend, fig_or_scene, (), legend_defaults, bbox; kwdict_complete = true)
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
function Legend(
        fig_or_scene,
        contentgroups::AbstractVector{<:AbstractVector},
        labelgroups::AbstractVector{<:AbstractVector},
        titles::AbstractVector;
        bbox = nothing, kwargs...
    )

    scene = get_scene(fig_or_scene)
    legend_defaults = block_defaults(:Legend, Dict{Symbol, Any}(kwargs), scene)
    entry_groups = to_entry_group(legend_defaults, contentgroups, labelgroups, titles)
    entrygroups = Observable(entry_groups)
    legend_defaults[:entrygroups] = entrygroups
    return _block(Legend, fig_or_scene, (), legend_defaults, bbox; kwdict_complete = true)
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
    return Legend(fig_or_scene, plots, labels, title; kwargs...)
end

function get_labeled_plots(ax; merge::Bool, unique::Bool)
    lplots = filter(get_plots(ax)) do plot
        haskey(plot.attributes, :label) ||
            plot isa PlotList && any(x -> haskey(x.attributes, :label), plot.plots)
    end
    labels = map(lplots) do l
        l.label[]
    end

    if any(x -> x isa AbstractVector, labels)
        _lplots = []
        _labels = []
        for (lplot, label) in zip(lplots, labels)
            if label isa AbstractVector
                for lab in label
                    push!(_lplots, lplot)
                    push!(_labels, lab)
                end
            else
                push!(_lplots, lplot)
                push!(_labels, label)
            end
        end
        lplots = _lplots
        labels = _labels
    end

    # filter out plots with same plot type and label
    if unique
        plots_labels = Base.unique(((p, l),) -> (typeof(p), l), zip(lplots, labels))
        lplots = first.(plots_labels)
        labels = last.(plots_labels)
    end

    if merge
        ulabels = Base.unique(labels)
        mergedplots = [
            [lp for (i, lp) in enumerate(lplots) if labels[i] == ul]
                for ul in ulabels
        ]

        lplots, labels = mergedplots, ulabels
    end

    lplots_with_overrides = map(lplots, labels) do plots, label
        if label isa Pair
            plots => LegendOverride(label[2])
        else
            plots
        end
    end
    labels = [label isa Pair ? label[1] : label for label in labels]

    return lplots_with_overrides, labels
end

get_plots(p::AbstractPlot) = [p]
# NOTE: this is important, since we know that `get_plots` is only ever called on the toplevel,
# we can assume that any plotlist on the toplevel should be decomposed into individual plots.
# However, if the user passes a label argument with a legend override, what do we do?
get_plots(p::PlotList) = haskey(p.attributes, :label) && p.attributes[:label] isa Pair ? [p] : p.plots

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
    return Legend(
        ax.parent, args...;
        bbox = ax.scene.viewport,
        margin = (6, 6, 6, 6),
        legend_position_to_aligns(position)...,
        kwargs...
    )
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

    return (halign = haligns[p[1]], valign = valigns[p[2]])
end

function legend_position_to_aligns(t::Tuple{Any, Any})
    return (halign = t[1], valign = t[2])
end

function foreach_plot(f, entry::LegendEntry)
    for element in entry.elements
        if !isnothing(element)
            for p in get_plots(element)
                f(p)
            end
        end
    end
    return
end

function toggle_visibility!(entry::LegendEntry, sync = false)
    foreach_plot(entry) do p
        p.visible = sync ? true : !p.visible[]
    end
    return
end

function get_plot_visibilities(entry::LegendEntry)
    visibilities = Observable{Bool}[]
    foreach_plot(entry) do p
        obs = ComputePipeline.get_observable!(p.visible)
        push!(visibilities, obs)
        return
    end
    return visibilities
end

function shade_visible_mode(visibilities)
    n_visible = sum(s -> Int64(s), visibilities)
    n_total = length(visibilities)
    # ignore shade if there is nothing to hide
    n_total == 0 && return :hide
    # hide shade if all are visible
    n_visible == n_total && return :hide
    # show shade if all are invisible
    n_visible == 0 && return :show
    # partly show shade if some but not all are visible
    return :halfshow
end

function attribute_examples(::Type{Legend})
    return Dict(
        :colgap => [
            Example(
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
            ),
        ],
        :groupgap => [
            Example(
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
            ),
        ],
        :patchsize => [
            Example(
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
            ),
        ],
        :patchlabelgap => [
            Example(
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
            ),
        ],
        :orientation => [
            Example(
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
            ),
        ],
        :nbanks => [
            Example(
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
