struct Figure
	scene::Scene
	layout::GridLayoutBase.GridLayout
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

struct Figureposition
    fig::Figure
    gp::GridLayoutBase.GridPosition
end

function Base.getindex(fig::Figure, rows, cols, side = GridLayoutBase.Inner())
    Figureposition(fig, fig.layout[rows, cols, side])
end

function Base.setindex!(fig::Figure, obj, rows, cols, side = GridLayoutBase.Inner())
    fig.layout[rows, cols, side] = obj
    push!(fig.content, obj)
end

Base.show(io::IO, fig::Figure) = print(io, "Figure ($(length(fig.content)) elements)")

Base.display(fig::Figure) = display(fig.scene)


struct FigureSubposition{T}
    parent::T
    rows
    cols
    side::GridLayoutBase.Side
end

function Base.getindex(parent::Union{Figureposition,FigureSubposition},
        rows, cols, side = GridLayoutBase.Inner())
    FigureSubposition(parent, rows, cols, side)
end

function Base.setindex!(parent::Union{Figureposition,FigureSubposition}, obj,
    rows, cols, side = GridLayoutBase.Inner())

    layout = find_or_make_layout!(parent)
    figure = get_figure(parent)
    layout[rows, cols, side] = obj
    push!(figure.content, obj)
end


function find_or_make_layout!(fp::Figureposition)
    c = contents(fp.gp, exact = true)
    layouts = filter(x -> x isa GridLayoutBase.GridLayout, c)
    if isempty(layouts)
        return fp.gp[] = GridLayoutBase.GridLayout()
    elseif length(layouts) == 1
        return only(layouts)
    else
        error("Found more than zero or one GridLayouts at $(fp.gp)")
    end
end

function find_or_make_layout!(layout::GridLayoutBase.GridLayout, fsp::FigureSubposition)
    gp = layout[fsp.rows, fsp.cols, fsp.side]
    c = contents(gp, exact = true)
    layouts = filter(x -> x isa GridLayoutBase.GridLayout, c)
    if isempty(layouts)
        return gp[] = GridLayoutBase.GridLayout()
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

