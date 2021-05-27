using Test, MakieCore

# Main tests live in Makie.jl, but we should write some unit tests going forward!
using MakieCore: @recipe, Attributes

@recipe(MyPlot) do scene
    Attributes(test = 222)
end
