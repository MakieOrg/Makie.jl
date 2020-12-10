function _precompile_()
    ccall(:jl_generating_output, Cint, ()) == 1 || return nothing
    @assert precompile(LLegend, (Scene, Node{Vector{Tuple{Optional{String}, Vector{LegendEntry}}}}))
    # @assert precompile(LLegend, (Scene, AbstractArray, Vector{String}))
    @assert precompile(LColorbar, (Scene,))
    # @assert precompile(LAxis, (Scene,))
    # @assert precompile(Core.kwfunc(Type), (NamedTuple{(:title,), Tuple{String}}, Type{LAxis}, Scene))
    @assert precompile(LineAxis, (Scene,))
    @assert precompile(LMenu, (Scene,))
    @assert precompile(LButton, (Scene,))
    @assert precompile(LSlider, (Scene,))
    @assert precompile(LTextbox, (Scene,))

    @assert precompile(layoutscene, ())  # doesn't fully precompile
    @assert precompile(get_ticklabels, (AbstractPlotting.Automatic, AbstractPlotting.Automatic, Vector{Float64}))
end
