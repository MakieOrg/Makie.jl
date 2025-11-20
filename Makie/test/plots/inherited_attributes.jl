function skipped_attributes(inheritor, parent)
    target = Set(keys(Makie.documented_attributes(inheritor).d))
    source = Set(keys(Makie.documented_attributes(parent).d))
    return setdiff(source, target)
end

# Check that every attribute of `parent` is also an attribute of `inheritor`,
# where both are plot types
function contains_all_attributes_of(inheritor, parent, exclude = Set{Symbol}())
    not_forwarded = skipped_attributes(inheritor, parent)
    return isempty(setdiff!(not_forwarded, exclude))
end

# Go through all attributes of a plot and check that they lead into another
# ComputeGraph. This implies that they affect one of the recipes child plots.
# (This is only valid for recipes that don't use Observables)
function all_attributes_connect_to_children(
        plot::Plot, exclude = Set{Symbol}(
            [
                :palettes, :dim_conversions, :cycle_index, :transform_func, :cycle,
                :model, :palette_lookup, :f32c,
            ]
        )
    )
    return all_attributes_connect_to_children(plot.attributes, exclude)
end

function all_attributes_connect_to_children(graph::Makie.ComputeGraph, exclude = Set{Symbol}())
    local_attributes = Symbol[]
    for (name, input) in graph.inputs
        name in exclude && continue

        if !leaves_graph(graph, input)
            push!(local_attributes, name)
        end
    end

    if !isempty(local_attributes)
        @error "One or more attributes did not get passed to child plots: $local_attributes"
        return false
    else
        return true
    end
end

function leaves_graph(graph, input::Makie.ComputePipeline.Input)
    for edge in input.dependents
        if leaves_graph(graph, edge)
            return true
        end
    end
    return false
end

function leaves_graph(graph, edge::Makie.ComputePipeline.ComputeEdge)
    if edge.graph !== graph
        return true
    end

    for edge in edge.dependents
        if leaves_graph(graph, edge)
            return true
        end
    end

    return false
end

@testset "Attribute completeness" begin

    @testset "ScatterLines" begin
        @test contains_all_attributes_of(ScatterLines, Scatter)
        @test contains_all_attributes_of(ScatterLines, Lines)
        f, a, p = scatterlines(rand(10))
        @test all_attributes_connect_to_children(p)
    end

end

@testset "Attributes() passthrough" begin
    # Plot construction should not overwrite `attr`
    attr = Attributes(color = :red)
    scene = Scene()
    p1 = scatter!(scene, attr, rand(10))
    p2 = scatter!(scene, attr, rand(10), color = :blue)
    p3 = scatter!(scene, attr, rand(10))

    @test p1.color[] == to_color(:red)
    @test p2.color[] == to_color(:blue)
    @test p3.color[] == to_color(:red)
    @test length(attr) == 1
end
