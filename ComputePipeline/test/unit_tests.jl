# Individual components

@testset "Graph Initialization" begin
    parent = ComputeGraph()
    add_input!(parent, :in1, 1)
    graph = ComputeGraph()
    add_input!(graph, :in1, parent.in1)
    add_input!(graph, :in2, 2)
    foo(inputs, changed, cached) = (inputs[1] + inputs[2],)
    register_computation!(foo, graph, [:in1, :in2], [:merged])

    @testset "Overwrite Errors" begin
        @test_throws ErrorException add_input!(parent, :in1, 1)
        @test_throws ErrorException add_input!(graph, :in1, 1)
        @test_throws ErrorException add_input!(graph, :in2, 1)
        @test_throws ErrorException add_input!(graph, :in1, parent.in1)
        @test_throws ErrorException add_input!(graph, :in2, parent.in1)

        # different inputs, same function = different edge -> error
        @test_throws ErrorException register_computation!(foo, graph, [:in1], [:merged])

        # same inputs, same function = same edge, this should work and not change the existing callback
        # TODO: How do we test that the edge does not get updated (to a new edge with the same content)?
        #       Is objectid sufficient?
        @test begin
            id = objectid(graph[:merged].parent)
            register_computation!(foo, graph, [:in1, :in2], [:merged])
            id == objectid(graph[:merged].parent)
        end

        # same inputs, different function = different edge -> error
        goo(inputs, changed, cached) = (inputs[1] * inputs[2],)
        @test_throws ErrorException register_computation!(goo, graph, [:in1, :in2], [:merged])
    end
end

@testset "Graph Interaction" begin
    graph = ComputeGraph()
    add_input!(graph, :in1, 1)
    add_input!(graph, :in2, 2)
    register_computation!(graph, [:in1, :in2], [:merged]) do inputs, changed, cached
        return (inputs[1] + inputs[2],)
    end

    # Sanity checks
    @test haskey(graph.inputs, :in1) && haskey(graph.inputs, :in2)
    @test haskey(graph.outputs, :in1) && haskey(graph.outputs, :in2) && haskey(graph.outputs, :merged)

    @testset "Graph Access" begin
        @test graph.in1 === graph.outputs[:in1]
        @test graph.in2 === graph.outputs[:in2]
        @test graph.merged === graph.outputs[:merged]

        @test graph[:in1] === graph.outputs[:in1]
        @test graph[:in2] === graph.outputs[:in2]
        @test graph[:merged] === graph.outputs[:merged]
    end

    @test graph[:merged][] == 3 # prepare graph state

    function get_state(graph)
        i = graph.inputs; o = graph.outputs
        return Int.(isdirty.([i[:in1], i[:in2], o[:in1], o[:in2], o[:merged]]))
    end

    @testset "Graph Update" begin
        update!(graph, in1 = 5)
        @test graph.inputs[:in1].value[] == 5
        @test get_state(graph) == [1, 0, 1, 0, 1]
        @test graph[:merged][] == 7

        @test_throws ErrorException update!(graph, merged = 2)
        @test get_state(graph) == [0, 0, 0, 0, 0]
        @test graph[:merged][] == 7

        update!(graph, in2 = 4, in1 = 7)
        @test get_state(graph) == [1, 1, 1, 1, 1]
        @test graph[:merged][] == 11

        graph.in2 = 0
        @test graph.inputs[:in2].value[] == 0
        @test get_state(graph) == [0, 1, 0, 1, 1]
        @test graph[:merged][] == 7

        graph.in1[] = 3
        @test graph.inputs[:in1].value[] == 3
        @test graph.outputs[:in1].value[] == 7
        @test get_state(graph) == [1, 0, 1, 0, 1]
        @test graph[:merged][] == 3
    end

    @testset "Graph resolve" begin
        update!(graph, in1 = 2, in2 = 1)
        @test get_state(graph) == [1, 1, 1, 1, 1]
        @test graph.inputs[:in1].value[] == 2
        @test graph.inputs[:in2].value[] == 1
        @test graph.outputs[:in1].value[] == 3
        @test graph.outputs[:in2].value[] == 0

        # getproperty interface
        @test graph.in1[] == 2
        @test graph.outputs[:in1].value[] == 2
        @test get_state(graph) == [0, 1, 0, 1, 1]

        @test graph.in2[] == 1
        @test graph.outputs[:in2].value[] == 1
        @test get_state(graph) == [0, 0, 0, 0, 1]

        @test graph.merged === graph.outputs[:merged]

        update!(graph, in1 = -1, in2 = -2)
        @test get_state(graph) == [1, 1, 1, 1, 1]
        @test graph.inputs[:in1].value[] == -1
        @test graph.inputs[:in2].value[] == -2
        @test graph.outputs[:in1].value[] == 2
        @test graph.outputs[:in2].value[] == 1

        # getindex interface
        @test graph[:in1][] == -1
        @test graph.outputs[:in1].value[] == -1
        @test get_state(graph) == [0, 1, 0, 1, 1]

        @test graph[:in2][] == -2
        @test graph.outputs[:in2].value[] == -2
        @test get_state(graph) == [0, 0, 0, 0, 1]

        # verify that this isn't a multi-step resolve
        graph.inputs[:in1].value = 7

        @test graph[:merged][] == -3
        @test graph.outputs[:merged].value[] == -3
        @test get_state(graph) == [0, 0, 0, 0, 0]

        # verify with parent being another compute edge too
        register_computation!(graph, [:merged], [:output]) do inputs, changed, cached
            return (inputs[1][],)
        end
        graph.outputs[:in1].value[] = 12
        @test graph[:output][] == -3
        @test graph.outputs[:output].value[] == -3
        @test get_state(graph) == [0, 0, 0, 0, 0]
        @test !isdirty(graph[:output])

        # multi-step with compute edge
        update!(graph, in1 = 10)
        @test get_state(graph) == [1, 0, 1, 0, 1]
        @test isdirty(graph[:output])
        @test graph[:output][] == 8
        @test graph.outputs[:output].value[] == 8
        @test get_state(graph) == [0, 0, 0, 0, 0]
        @test !isdirty(graph[:output])
    end

    counter = Dict{Symbol, Int}()
    foreach(k -> counter[k] = 0, [:merged, :merged2, :zipped, :summed, :plus_one, :zipped2, :summed2, :plus_one2])
    graph = ComputeGraph()
    add_input!(graph, :in1, 1)
    add_input!(graph, :in2, 2)
    add_input!(graph, :in3, [1, 2, 3])
    # bitstype
    register_computation!(graph, [:in1, :in2], [:merged]) do inputs, changed, cached
        counter[:merged] += 1
        return (changed.in1 ? inputs[1] + inputs[2] : nothing,)
    end
    register_computation!(graph, [:merged], [:merged2]) do inputs, changed, cached
        counter[:merged2] += 1
        return (inputs.merged,)
    end
    # Array recreate
    register_computation!(graph, [:in1, :in3], [:zipped]) do inputs, changed, cached
        counter[:zipped] += 1
        return (inputs.in1 .+ inputs.in3,)
    end
    register_computation!(graph, [:zipped], [:summed]) do inputs, changed, cached
        counter[:summed] += 1
        return (sum(inputs.zipped),)
    end
    register_computation!(graph, [:summed], [:plus_one]) do inputs, changed, cached
        counter[:plus_one] += 1
        return (inputs.summed + 1,)
    end
    # Array overwrite/reuse
    register_computation!(graph, [:in1, :in3], [:zipped2]) do inputs, changed, cached
        output = isnothing(cached) ? [0, 0, 0] : cached.zipped2
        output .= inputs.in1 .+ inputs.in3
        counter[:zipped2] += 1
        return (output,)
    end
    register_computation!(graph, [:zipped2], [:summed2]) do inputs, changed, cached
        counter[:summed2] += 1
        return (sum(inputs.zipped2),)
    end
    register_computation!(graph, [:summed2], [:plus_one2]) do inputs, changed, cached
        counter[:plus_one2] += 1
        return (inputs.summed2 + 1,)
    end

    @testset "update skipping and changed" begin
        @testset "initialization" begin
            @test graph.merged2[] == 3
            @test counter[:merged] == 1
            @test counter[:merged2] == 1

            @test graph.plus_one[] == 10
            @test counter[:zipped] == 1
            @test counter[:summed] == 1
            @test counter[:plus_one] == 1

            @test graph.plus_one2[] == 10
            @test counter[:zipped2] == 1
            @test counter[:summed2] == 1
            @test counter[:plus_one2] == 1
        end

        @testset "explicit skip via return nothing" begin
            graph.in2 = 3
            @test graph.merged2[] == 3
            @test counter[:merged] == 2
            @test counter[:merged2] == 1
        end

        @testset "no skip" begin
            graph.in1 = 2
            @test graph.merged2[] == 5
            @test counter[:merged] == 3
            @test counter[:merged2] == 2

            graph.in1 = 5
            @test graph.merged2[] == 8
            @test counter[:merged] == 4
            @test counter[:merged2] == 3

            graph.in1 = 4
            graph.in2 = 5
            @test graph.merged2[] == 9
            @test counter[:merged] == 5
            @test counter[:merged2] == 4

            # from in1 updates
            @test graph.plus_one[] == 19
            @test counter[:zipped] == 2
            @test counter[:summed] == 2
            @test counter[:plus_one] == 2

            @test graph.plus_one2[] == 19
            @test counter[:zipped2] == 2
            @test counter[:summed2] == 2
            @test counter[:plus_one2] == 2

            # from in3 updates
            graph.in3 = [0, 1, 2]
            @test graph.plus_one[] == 16
            @test counter[:zipped] == 3
            @test counter[:summed] == 3
            @test counter[:plus_one] == 3

            @test graph.plus_one2[] == 16
            @test counter[:zipped2] == 3
            @test counter[:summed2] == 3
            @test counter[:plus_one2] == 3
        end

        @testset "same value skips" begin
            graph.in1 = 4
            @test graph.merged2[] == 9
            @test counter[:merged] == 5
            @test counter[:merged2] == 4

            # from in1
            @test graph.plus_one[] == 16
            @test counter[:zipped] == 3
            @test counter[:summed] == 3
            @test counter[:plus_one] == 3

            @test graph.plus_one2[] == 16
            @test counter[:zipped2] == 3
            @test counter[:summed2] == 3
            @test counter[:plus_one2] == 3

            # from in3
            graph.in3 = [0, 1, 2]
            @test graph.plus_one[] == 16
            @test counter[:zipped] == 3
            @test counter[:summed] == 3
            @test counter[:plus_one] == 3

            @test graph.plus_one2[] == 16
            @test counter[:zipped2] == 3
            @test counter[:summed2] == 3
            @test counter[:plus_one2] == 3

            # delayed same value
            graph.in3 = [2, 1, 0]
            @test graph.plus_one[] == 16
            @test counter[:zipped] == 4     # input: [2,1,0] != [0,1,2]
            @test counter[:summed] == 4     # input: [2,1,0] .+ 4 != [0,1,2] .+ 4
            @test counter[:plus_one] == 3   # input:       sum(^) == sum(^)

            @test graph.plus_one2[] == 16
            @test counter[:zipped2] == 4
            @test counter[:summed2] == 4
            @test counter[:plus_one2] == 3
        end

        @testset "Array edge case" begin
            graph.in3 = [3, 2, 1] # .+ 1
            graph.in1 = 3       #  - 1

            # new array generated, values match, update skipped
            @test graph.plus_one[] == 16
            @test counter[:zipped] == 5
            @test counter[:summed] == 4
            @test counter[:plus_one] == 3

            # old array reused, values can't be compared, update advances
            @test graph.plus_one2[] == 16
            @test counter[:zipped2] == 5
            @test counter[:summed2] == 5
            @test counter[:plus_one2] == 3
        end
    end
end

@testset "Graph io" begin
    parent = ComputeGraph()
    add_input!(parent, :in1, 1)
    graph = ComputeGraph()
    add_input!(graph, :in1, parent.in1)
    add_input!(graph, :in2, 2)
    foo2(inputs, changed, cached) = (inputs[1] + inputs[2], inputs[1] - inputs[2])
    register_computation!(foo2, graph, [:in1, :in2], [:added, :subtracted])
    bar(inputs, changed, cached) = (inputs[1],)
    register_computation!(bar, graph, [:added], [:output])
    register_computation!(bar, graph, [:output], [:output2])
    register_computation!(bar, graph, [:subtracted], [:output3])

    graph[:in1][]

    @testset "brief show()" begin
        # TODO: This counts edges in graph because part of graph continues parent - Should it?
        @test sprint(show, parent) == "ComputeGraph(1 input, 1 output, 5 edges)"
        @test sprint(show, graph) == "ComputeGraph(1 input, 7 outputs, 5 edges)"
        @test sprint(show, graph.inputs[:in2]) == "Input(:in2, 2)"
        @test sprint(show, graph[:in1]) == "Computed(:in1, 1)"
        @test sprint(show, graph[:in2]) == "Computed(:in2, #undef)"
        @test sprint(show, graph[:added].parent) == "ComputeEdge(foo2(…), 2 inputs, 2 outputs, 2 dependents)"
        @test sprint(show, graph[:output].parent) == "ComputeEdge(bar(…), 1 input, 1 output, 1 dependent)"
        @test sprint(show, graph[:output2].parent) == "ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)"
    end

    @testset "brief show()" begin
        m = MIME"text/plain"()
        @test sprint(show, m, parent) == "ComputeGraph():\n  Inputs:\n    :in1 => Input(:in1, 1)\n\n  Outputs:\n    :in1 => Computed(:in1, 1)"
        @test sprint(show, m, graph) == "ComputeGraph():\n  Inputs:\n    :in2 => Input(:in2, 2)\n\n  Outputs:\n    :added      => Computed(:added, #undef)\n    :in1        => Computed(:in1, 1)\n    :in2        => Computed(:in2, #undef)\n    :output     => Computed(:output, #undef)\n    :output2    => Computed(:output2, #undef)\n    :output3    => Computed(:output3, #undef)\n    :subtracted => Computed(:subtracted, #undef)"

        # Work around function path that's printed
        s = sprint(show, m, graph.inputs[:in2])
        @test contains(s, "Input:\n  name:     :in2\n  value:    2\n  callback: identity(::Int64) @ ")
        @test contains(s, "\n  output:   ↻ Computed(:in2, #undef)\n  dependents:\n    ↻ ComputeEdge(foo2(…), 2 inputs, 2 outputs, 2 dependents)")

        @test sprint(show, m, graph[:in1]) == "Computed:\n  name = :in1\n  parent = ComputeEdge(compute_identity(…), 1 input, 1 output, 1 dependent) @ output 1\n  value = 1\n  dirty = false"
        @test sprint(show, m, graph[:in2]) == "Computed:\n  name = :in2\n  parent = Input(:in2, 2)\n  value = #undef\n  dirty = true"

        # regex needed for 1.6 which uses "NameTuple{(), Tuple{}}" instead o "@NamedTuple{}"
        s = sprint(show, m, graph[:added].parent)
        @test contains(s, r"ComputeEdge:\n  callback:\n    foo2\(::@?NamedTuple\{.*\}, ::@?NamedTuple\{.*\}, ::Nothing\)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:in1, 1)\n    ↻ Computed(:in2, #undef)\n  outputs:\n    ↻ Computed(:added, #undef)\n    ↻ Computed(:subtracted, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 1 dependent)\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output].parent)
        @test contains(s, r"ComputeEdge:\n  callback:\n    bar\(::@?NamedTuple\{.*\}, ::@?NamedTuple\{.*\}, ::Nothing\)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:added, #undef)\n  outputs:\n    ↻ Computed(:output, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output2].parent)
        @test contains(s, r"ComputeEdge:\n  callback:\n    bar\(::@?NamedTuple\{.*\}, ::@?NamedTuple\{.*\}, ::Nothing\)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:output, #undef)\n  outputs:\n    ↻ Computed(:output2, #undef)\n  dependents:")
    end
end

@testset "deletion" begin
    foo(inputs, changed, cached) = (inputs[1],)
    foo2(inputs, changed, cached) = (inputs[1] + inputs[2], inputs[1] - inputs[2])

    @testset "public interface" begin
        graph = ComputeGraph()
        add_input!(graph, :in, 1)
        register_computation!(foo, graph, [:in], [:out])

        # These should not be available
        @test_throws MethodError delete!(graph, graph.inputs[:in]) # Input
        @test_throws MethodError delete!(graph, graph.outputs[:in]) # Computed
        @test_throws MethodError delete!(graph, graph.outputs[:out].parent) # ComputeEdge

        @test_throws KeyError delete!(graph, :unknown)

        @test begin
            delete!(graph, :out); true
        end
    end

    @testset "Input" begin
        graph = ComputeGraph()
        add_input!(graph, :in, 1)

        # Deleting an input should be possible and delete both the Input and the
        # related Computed if there are no obstructions
        @test haskey(graph.inputs, :in)
        @test haskey(graph.outputs, :in)
        delete!(graph, :in)
        @test !haskey(graph.inputs, :in)
        @test !haskey(graph.outputs, :in)

        add_input!(graph, :in, 1)
        @test haskey(graph.inputs, :in)
        @test haskey(graph.outputs, :in)

        register_computation!(foo, graph, [:in], [:out])

        # Deleting an input node with dependents is not allowed
        @test_throws ErrorException delete!(graph, :in)

        # Unless you allow deleting child nodes
        delete!(graph, :in, recursive = true)
        @test !haskey(graph.inputs, :in)
        @test !haskey(graph.outputs, :in)
        @test !haskey(graph.outputs, :out)
    end

    @testset "Computed" begin
        parent = ComputeGraph()
        add_input!(parent, :parent_node, 1)

        graph = ComputeGraph()
        add_input!(graph, :in1, parent.parent_node)
        add_input!(graph, :in2, 2)

        # Deleting a leaf node without siblings is valid
        @testset "Leaf Node" begin
            # ... with a Computed --> Computed --> Computed
            register_computation!(foo, graph, [:in1], [:output])

            @test haskey(graph.outputs, :output)
            @test !isempty(graph.outputs[:in1].parent.dependents)
            delete!(graph, :output)
            @test !haskey(graph.outputs, :output)
            @test isempty(graph.outputs[:in1].parent.dependents)

            # ... with a Input --> Computed --> Computed
            register_computation!(foo, graph, [:in2], [:output])

            @test haskey(graph.outputs, :output)
            @test !isempty(graph.outputs[:in2].parent.dependents)
            delete!(graph, :output)
            @test !haskey(graph.outputs, :output)
            @test isempty(graph.outputs[:in2].parent.dependents)
        end

        # Deleting a leaf node with siblings requires force = true
        @testset "Siblings" begin
            register_computation!(foo2, graph, [:in1, :in2], [:added, :subtracted])

            @test_throws ErrorException delete!(graph, :added)
            @test !isempty(graph.outputs[:in1].parent.dependents)
            @test !isempty(graph.outputs[:in2].parent.dependents)
            @test haskey(graph.outputs, :added)
            @test haskey(graph.outputs, :subtracted)

            delete!(graph, :added, force = true)
            @test isempty(graph.outputs[:in1].parent.dependents)
            @test isempty(graph.outputs[:in2].parent.dependents)
            @test !haskey(graph.outputs, :added)
            @test !haskey(graph.outputs, :subtracted)

            # check symmetry
            register_computation!(foo2, graph, [:in1, :in2], [:added, :subtracted])
            @test_throws ErrorException delete!(graph, :subtracted)
            @test !isempty(graph.outputs[:in1].parent.dependents)
            @test !isempty(graph.outputs[:in2].parent.dependents)
            @test haskey(graph.outputs, :added)
            @test haskey(graph.outputs, :subtracted)

            delete!(graph, :subtracted, force = true)
            @test isempty(graph.outputs[:in1].parent.dependents)
            @test isempty(graph.outputs[:in2].parent.dependents)
            @test !haskey(graph.outputs, :added)
            @test !haskey(graph.outputs, :subtracted)
        end

        # Deleting a node with further children requires recursive = true
        @testset "Children" begin
            register_computation!(foo, graph, [:in1], [:output])
            register_computation!(foo, graph, [:output], [:output2])

            @test_throws ErrorException delete!(graph, :output)
            @test haskey(graph.outputs, :output)
            @test haskey(graph.outputs, :output2)
            @test !isempty(graph.outputs[:in1].parent.dependents)
            @test !isempty(graph.outputs[:output].parent.dependents)

            delete!(graph, :output, recursive = true)
            @test !haskey(graph.outputs, :output)
            @test !haskey(graph.outputs, :output2)
            @test isempty(graph.outputs[:in1].parent.dependents)
        end

        # Nodes that connect one graph to another should follow the same rules
        # as normal nodes
        @testset "Graph Connector Node" begin
            @test haskey(parent.outputs, :parent_node)
            @test haskey(graph.outputs, :in1)
            @test !isempty(parent.outputs[:parent_node].parent.dependents)
            @test isempty(graph.outputs[:in1].parent.dependents)

            @test_throws KeyError delete!(graph, :parent_node)

            delete!(graph, :in1)
            @test haskey(parent.outputs, :parent_node)
            @test !haskey(graph.outputs, :in1)
            @test isempty(parent.outputs[:parent_node].parent.dependents)

            add_input!(graph, :in1, parent.parent_node)
            register_computation!(foo, graph, [:in1], [:output])

            @test haskey(parent.outputs, :parent_node)
            @test haskey(graph.outputs, :in1)
            @test haskey(graph.outputs, :output)
            @test !isempty(parent.outputs[:parent_node].parent.dependents)
            @test !isempty(graph.outputs[:in1].parent.dependents)
            @test isempty(graph.outputs[:output].parent.dependents)

            @test_throws ErrorException delete!(graph, :in1)

            delete!(graph, :in1, recursive = true)
            @test haskey(parent.outputs, :parent_node)
            @test !haskey(graph.outputs, :in1)
            @test !haskey(graph.outputs, :output)
            @test isempty(parent.outputs[:parent_node].parent.dependents)

            # TODO:: Anything special for graph barriers?
        end
    end

end

@testset "Observables" begin
    @testset "Synchronization" begin
        g = ComputeGraph()
        add_input!((k, x) -> Float32.(x), g, :input1, [0])
        add_input!((k, x) -> Float32.(x), g, :input2, [1])
        register_computation!(g, [:input1, :input2], [:xy, :yx]) do (x, y), changed, cached
            return ([x; y], [y; x])
        end
        map!(x -> [x; 1], g, :xy, :out1)
        map!(x -> [x; 1], g, :yx, :out2)
        map!((x, y) -> tuple.(x, y), g, [:out1, :out2], :zipped)
        foreach(key -> ComputePipeline.get_observable!(g, key), keys(g.outputs))

        @testset "Initialization" begin
            @test haskey(g, :input1)
            @test haskey(g, :input2)
            @test haskey(g, :xy)
            @test haskey(g, :yx)
            @test haskey(g, :out1)
            @test haskey(g, :out2)
            @test haskey(g, :zipped)

            @test g.observables[:input1][] == Float32[0]
            @test g.observables[:input2][] == Float32[1]
            @test g.observables[:xy][] == Float32[0, 1]
            @test g.observables[:yx][] == Float32[1, 0]
            @test g.observables[:out1][] == Float32[0, 1, 1]
            @test g.observables[:out2][] == Float32[1, 0, 1]
            @test g.observables[:zipped][] == [(0.0f0, 1.0f0), (1.0f0, 0.0f0), (1.0f0, 1.0f0)]
        end

        @testset "Update" begin
            ComputePipeline.update!(g, input1 = [2, 3], input2 = [6, 7])

            @test g.observables[:input1][] == Float32[2, 3]
            @test g.observables[:input2][] == Float32[6, 7]
            @test g.observables[:xy][] == Float32[2, 3, 6, 7]
            @test g.observables[:yx][] == Float32[6, 7, 2, 3]
            @test g.observables[:out1][] == Float32[2, 3, 6, 7, 1]
            @test g.observables[:out2][] == Float32[6, 7, 2, 3, 1]
            @test g.observables[:zipped][] == tuple.(Float32[2, 3, 6, 7, 1], Float32[6, 7, 2, 3, 1])
        end
    end

    @testset "map and on" begin
        g = ComputeGraph()
        add_input!((k, x) -> Float64.(x), g, :input1, 0)
        add_input!((k, x) -> Float64.(x), g, :input2, 4)
        register_computation!(g, [:input1, :input2], [:xy, :yx]) do (x, y), changed, cached
            return (x - y, y - x)
        end
        map!(x -> x + 1, g, :xy, :out1)
        map!(x -> x + 1, g, :yx, :out2)
        map!((x, y) -> x * y, g, [:out1, :out2], :mult)

        @test isempty(g.observables)

        obs = Observable{Any}()
        on(x -> obs[] = x, g[:mult])
        @test_throws UndefRefError obs[]
        @test haskey(g.observables, :mult)
        @test length(g.observables) == 1
        update!(g, input1 = 1)

        obs2 = map(x -> 2 .* x, g.out2)
        @test obs2[] == 8.0
        @test haskey(g.observables, :out2)
        @test length(g.observables) == 2

        obs3 = Observable{Any}()
        map!(*, obs3, g.input1, g.out1)
        @test obs3[] == -2.0
        @test haskey(g.observables, :input1)
        @test haskey(g.observables, :out1)
        @test length(g.observables) == 4

        counter = Ref(0)
        onany(obs, obs2, obs3) do args...
            counter[] += 1
            return
        end
        ComputePipeline.update!(g, input1 = 2, input2 = 8)
        @test counter[] == 4
    end

    @testset "Infinite loops" begin
        g = ComputeGraph()
        add_input!(g, :resample, 1)
        register_computation!(g, [:resample], [:output]) do (resample,), changed, cached
            data = isnothing(cached) ? collect(1:10) : cached[1]
            return (resample > 0 ? shuffle!(data) : data,)
        end
        obs = ComputePipeline.get_observable!(g, :output)

        update_counter = Ref(0)
        on(x -> update_counter[] += 1, obs)
        @testset "Problem" begin
            # Updating mutable data to the same value can cause infinite loops
            # if the Observable also updates (and then loops back into the graph)
            # We want this to never trigger:
            prev = deepcopy(g[:output][])
            @test g[:output][] !== prev # Sanity check
            @test obs[] !== prev # Sanity check
            for i in 1:10
                update!(g, resample = -i) # don't change data
                @test g[:output][] == prev # Sanity check
                @test obs[] == prev # Sanity check
                @test update_counter[] == 0
            end

            # And updating still works
            prev = deepcopy(g[:output][])
            update_counter[] = 0
            @test g[:output][] !== prev # Sanity check
            @test obs[] !== prev # Sanity check
            for i in 1:10
                prev = deepcopy(g[:output][])
                update!(g, resample = i) # shuffle data
                @test g[:output][] != prev # Sanity check
                @test obs[] != prev # Sanity check
                @test obs[] == g[:output][]
                @test update_counter[] == i
            end

            # Mixed for good measure
            prev = deepcopy(g[:output][])
            update_counter[] = 0
            expected = 0
            for i in 1:30
                choice = rand(Int)
                prev = deepcopy(g[:output][])
                update!(g, resample = choice) # maybe shuffle data
                if choice > 0
                    expected += 1
                    @test obs[] != prev
                else
                    @test obs[] == prev
                end
                @test obs[] == g[:output][]
                @test update_counter[] == expected
            end
        end

        @testset "Solution" begin
            # Keep observable and compute data distinguishable
            @test obs[] == g[:output][]
            @test obs[] !== g[:output][]

            for i in 1:10
                update!(g, resample = -i)
                @test obs[] == g[:output][]
                @test obs[] !== g[:output][]
            end

            for i in 1:10
                update!(g, resample = i)
                @test obs[] == g[:output][]
                @test obs[] !== g[:output][]
            end

            for i in 1:30
                choice = rand(Int)
                update!(g, resample = choice)
                @test obs[] == g[:output][]
                @test obs[] !== g[:output][]
            end
        end
    end
end

@testset "mark_resolved" begin
    @testset "Input" begin
        graph = ComputeGraph()
        add_input!(graph, :in, 1)
        map!(identity, graph, :in, :out)
        @test graph.out[] == 1
        @test !ComputePipeline.isdirty(graph.out)

        graph.in = 2
        @test ComputePipeline.isdirty(graph.out)
        ComputePipeline.mark_resolved!(graph.out)
        @test !ComputePipeline.isdirty(graph.out)
        @test graph.out[] == 1

        graph.in = 3
        @test ComputePipeline.isdirty(graph.out)
        @test graph.out[] == 3
    end

    @testset "ComputeEdge" begin
        g = ComputeGraph()
        add_input!(g, :input1, 0)
        add_input!(g, :input2, 1)
        map!(x -> x + 1, g, :input1, :out1)
        map!(x -> x + 1, g, :input2, :out2)
        map!(tuple, g, [:out1, :out2], :output)

        @test g.output[] == (1, 2)
        @test !ComputePipeline.isdirty(g.output)

        g.input1 = 2
        @test ComputePipeline.isdirty(g.output)
        ComputePipeline.mark_resolved!(g.output)
        @test !ComputePipeline.isdirty(g.output)
        @test g.output[] == (1, 2)

        g.input2 = 2
        @test ComputePipeline.isdirty(g.output)
        @test g.output[] == (3, 3)

        g.input1 = 0
        ComputePipeline.mark_resolved!(g.output)
        @test g.output[] == (3, 3)
        g.input1 = 1
        @test g.output[] == (2, 3)
    end
end

@testset "Validation" begin
    graph = ComputeGraph()
    add_input!(graph, :a, 1)

    @test_throws ErrorException add_input!(graph, :b, Ref(graph.a))
    @test_throws ErrorException add_input!(graph, :c, Ref(graph.inputs[:a]))
    @test_throws ErrorException add_input!(graph, :d, graph.inputs[:a])

    # add_input!() processes this, so we need to check more manually
    graph.outputs[:dummy] = ComputePipeline.Computed(:dummy)
    @test_throws ErrorException ComputePipeline.Input(graph, :e, graph.a, identity, graph.dummy)

    @test_throws ErrorException ComputePipeline.Computed(:f, Ref(Ref(graph.a)))
    @test_throws ErrorException ComputePipeline.Computed(:g, Ref(graph.a))
    @test_throws ErrorException ComputePipeline.Computed(:h, Ref(Ref(graph.inputs[:a])))
    @test_throws ErrorException ComputePipeline.Computed(:i, Ref(graph.inputs[:a]))

    map!(x -> graph.a, graph, :a, :j)
    @test_throws ResolveException{ErrorException} graph.j[]
end

@testset "mixed-map" begin
    graph1 = ComputeGraph()
    add_input!(graph1, :a1, 1)

    graph2 = ComputeGraph()
    add_input!(graph2, :a2, 1)

    map!(+, graph1, [graph1[:a1], graph2[:a2]], :merged1)
    e1 = graph1.merged1.parent
    @test e1.inputs == [graph1.a1, graph2.a2]

    map!(+, graph1, [:a1, graph2[:a2]], :merged2)
    e2 = graph1.merged2.parent
    @test e2.inputs == [graph1.a1, graph2.a2]

    map!(+, graph2, [graph1[:a1], :a2], :merged3)
    e3 = graph2.merged3.parent
    @test e3.inputs == [graph1.a1, graph2.a2]
end

@testset "compute_identity" begin
    graph1 = ComputeGraph()
    add_input!(graph1, :a1, Ref{Any}(1))
    map!(x -> Ref{Any}(x), graph1, :a1, :b1)

    graph2 = ComputeGraph()
    add_input!(graph2, :b1, graph1.b1)
    graph2.b1[]
    @test graph2.b1.value isa Ref{Any}

    edge = graph2.b1.parent
    @test edge.callback == ComputePipeline.compute_identity
    @test length(edge.inputs) == length(edge.outputs)
    for (in, out) in zip(edge.inputs, edge.outputs)
        @test in.value === out.value
        @test !ComputePipeline.isdirty(in)
        @test !ComputePipeline.isdirty(out)
    end

    update!(graph1, a1 = 5.0)

    for (in, out) in zip(edge.inputs, edge.outputs)
        @test in.value === out.value
        @test ComputePipeline.isdirty(in)
        @test ComputePipeline.isdirty(out)
    end

    graph1.b1[]

    for (in, out) in zip(edge.inputs, edge.outputs)
        @test in.value === out.value
        @test !ComputePipeline.isdirty(in)
        @test ComputePipeline.isdirty(out)
    end

    graph2.b1[]

    for (in, out) in zip(edge.inputs, edge.outputs)
        @test in.value === out.value
        @test !ComputePipeline.isdirty(in)
        @test !ComputePipeline.isdirty(out)
    end
end
