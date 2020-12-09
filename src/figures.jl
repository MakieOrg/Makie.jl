struct Figure
	scene::Scene
	layout::GridLayout
	content::Vector
    attributes::Attributes
    
    function Figure(args...)
        f = new(args...)
        current_figure!(f)
        f
    end
end

const _current_figure = Ref{Union{Nothing, Figure}}(nothing)
current_figure() = _current_figure[]
current_figure!(fig) = (_current_figure = fig)

function Figure(; kwargs...)
    scene, layout = layoutscene(; kwargs...)
    Figure(
        scene,
        layout,
        [],
        Attributes()
    )
end

export Figure

function plot(P::PlotFunc, args...; axis = (;), figure = (;), kw_attributes...)
    # scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; figure...)
    ax = LAxis(fig.scene; axis...)
    fig.layout[1, 1] = ax
    push!(fig.content, ax)
    p = plot!(ax, P, Attributes(kw_attributes), args...)
    (figure = fig, axis = ax, plot = p)
end

struct Figureposition
    fig::Figure
    gp::MakieLayout.GridLayoutBase.GridPosition
end

function Base.getindex(fig::Figure, rows, cols, side = MakieLayout.GridLayoutBase.Inner())
    Figureposition(fig, fig.layout[rows, cols, side])
end

function Base.setindex!(fig::Figure, obj, rows, cols, side = MakieLayout.GridLayoutBase.Inner())
    fig.layout[rows, cols, side] = obj
    push!(fig.content, obj)
end

Base.show(io::IO, fig::Figure) = print(io, "Figure ($(length(fig.content)) elements)")

Base.display(fig::Figure) = display(fig.scene)
Base.display(nt::NamedTuple{(:figure, :axis, :plot), <:Tuple{Figure, Any, Any}}) = display(nt.figure)


function plot(P::PlotFunc, fp::Figureposition, args...; axis = (;), kwargs...)

    @assert isempty(contents(fp.gp, exact = true))

    ax = fp.gp[] = LAxis(fp.fig.scene; axis...)
    p = plot!(P, ax, args...; kwargs...)
    (axis = ax, plot = p)
end

function plot!(P::PlotFunc, fp::Figureposition, args...; kwargs...)

    c = contents(fp.gp, exact = true)
    if !(length(c) == 1 && c[1] isa Union{LAxis, LScene})
        error("There is not just one axis at $(fp.gp).")
    end
    ax = only(c)
    plot!(P, ax, args...; kwargs...)

end

struct FigureSubposition{T}
    parent::T
    rows
    cols
    side::MakieLayout.GridLayoutBase.Side
end

function Base.getindex(parent::Union{Figureposition,FigureSubposition},
        rows, cols, side = MakieLayout.GridLayoutBase.Inner())
    FigureSubposition(parent, rows, cols, side)
end

function Base.setindex!(parent::Union{Figureposition,FigureSubposition}, obj,
    rows, cols, side = MakieLayout.GridLayoutBase.Inner())

    layout = find_or_make_layout!(parent)
    figure = get_figure(parent)
    layout[rows, cols, side] = obj
    push!(figure.content, obj)
end

function find_or_make_layout!(fp::Figureposition)
    c = contents(fp.gp, exact = true)
    layouts = filter(x -> x isa GridLayout, c)
    if isempty(layouts)
        return fp.gp[] = GridLayout()
    elseif length(layouts) == 1
        return only(layouts)
    else
        error("Found more than zero or one GridLayouts at $(fp.gp)")
    end
end

function find_or_make_layout!(layout::GridLayout, fsp::FigureSubposition)
    gp = layout[fsp.rows, fsp.cols, fsp.side]
    c = contents(gp, exact = true)
    layouts = filter(x -> x isa GridLayout, c)
    if isempty(layouts)
        return gp[] = GridLayout()
    elseif length(layouts) == 1
        return only(layouts)
    else
        error("Found more than zero or one GridLayouts at $(gp)")
    end
end

function find_or_make_layout!(fsp::FigureSubposition)
    layout = find_or_make_layout!(fsp.parent)
    find_or_make_layout!(layout, fsp)
end


get_figure(fsp::FigureSubposition) = get_figure(fsp.parent)
get_figure(fp::Figureposition) = fp.fig