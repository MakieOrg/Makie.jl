# ComputePipeline

[![ComputePipeline](https://github.com/MakieOrg/Makie.jl/actions/workflows/compute-pipeline.yml/badge.svg)](https://github.com/MakieOrg/Makie.jl/actions/workflows/compute-pipeline.yml)

The Makie computegraph package for reactive computations and conversions.
Replaces [Observables.jl](https://github.com/JuliaGizmos/Observables.jl) for Makie's internals.

The documentation is part of the Makie docs: https://docs.makie.org/dev/explanations/compute-pipeline#Compute-Pipeline


Quickstart:
```julia
graph = ComputeGraph()

# add inputs
add_input!(graph, :input1, 1)
add_input!((key, value) -> Float32(value), graph, :input2, 2) # directly converts

# add computations (edges + output nodes)
register_computation!(graph, [:input1, :input2], [:output]) do inputs, changed, last_output
    input1, input2 = inputs
    return (input1 + input2, )
end

# Observable like API:
map!((a, b) -> a + b, graph, [:input1, :input2], :output)
map!((a, b) -> ([a, b], [b, a]), graph, [:input1, :input2], [:ab, :ba])
```
