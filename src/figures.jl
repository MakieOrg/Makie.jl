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
    scene, layout = layoutscene()
    Figure(
        scene,
        layout,
        [],
        Attributes(kwargs)
    )
end

export Figure

function plot(P::PlotFunc, attrs::Attributes, args...; kw_attributes...)
    attributes = merge!(Attributes(kw_attributes), attrs)
    scene_attributes = extract_scene_attributes!(attributes)
    fig = Figure(; scene_attributes...)
    ax = LAxis(fig.scene)
    fig.layout[1, 1] = ax
    push!(fig.content, ax)
    p = plot!(ax, P, attributes, args...)
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


function plot(P::PlotFunc, fp::Figureposition, args...; kwargs...)

    @assert isempty(contents(fp.gp, exact = true))

    ax = fp.gp[] = LAxis(fp.fig.scene)
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