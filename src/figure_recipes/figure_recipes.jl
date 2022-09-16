function default_attrs end

macro figure_recipe(f, symbol)
    symesc = esc(symbol)
    symesc_mut = esc(Symbol(symbol, "!"))
    quote
        function $symesc(args...; kwargs...)
            plot_figure_recipe($symesc, args...; kwargs...)
        end
        function $symesc_mut(args...; kwargs...)
            plot_figure_recipe!($symesc, args...; kwargs...)
        end
        function Makie.default_attrs(::typeof($symesc))
            $f()
        end
    end
end

function plot_figure_recipe(f::Function, args...; kwargs...)
    kwargs_dict = Dict(kwargs)
    attrs = default_attrs(f)
    figure_kws = pop!(kwargs_dict, :figure, (;))
    fig = Figure(; figure_kws...)
    result = plot_figure_recipe!(f, fig, fig.layout, attrs, args...; kwargs_dict...)
    fig, result
end

function plot_figure_recipe!(f::Function, g::GridPosition, attrs::Attributes, args...; kwargs...)
    l = GridLayoutBase.get_layout_at!(g; createmissing = true)
    fig = get_top_parent(g)
    if !(fig isa Figure)
        error("GridLayout top parent is not a Figure.")
    end
    result = plot_figure_recipe!(f, fig, l, attrs, args...; kwargs...)
    fig, result
end

function plot_figure_recipe!(f::Function, g::GridPosition, args...; kwargs...)
    attrs = default_attrs(f)
    plot_figure_recipe!(f, g, attrs, args...; kwargs...)
end



