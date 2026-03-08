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

        @testset "Recursive Loop" begin
            graph = ComputeGraph()
            add_input!(graph, :input, 0)
            map!(x -> (x, x), graph, :input, [:out1, :out2])

            triggered = Symbol[]
            on(graph.out1) do x
                push!(triggered, :obs1)
                if isodd(x)
                    graph.input = x + 1
                end
                return
            end
            on(graph.out2) do x
                push!(triggered, :obs2)
                if isodd(x)
                    graph.input = x + 1
                end
                return
            end

            @test graph.input[] == 0
            @test isempty(triggered)

            graph.input = 1
            # one obs should trigger the 1 + 1
            # this causes out1, out2 to update and be marked as changed
            # this triggers on(onchange) again (from inside on(onchange))
            # this should update obs1.val and obs2.val and then mark both as outdated
            # and then trigger all that are marked outdated, which should not contain copies
            # so it should trigger both here, with neither updating the graph
            # we should then step back to the original on(onchange)
            # which should not have anything left to process as the inner on(onchange) processed everything
            @test triggered == [:obs1, :obs1, :obs2] || triggered == [:obs2, :obs2, :ob1]
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

@testset "is_same NaN and missing" begin
    # vectors
    v = [NaN, missing, 1]
    @test ComputePipeline.is_same(v, copy(v))
    @test !ComputePipeline.is_same(v, v)

    # Dicts with NaN
    d = Dict(:a => NaN, :b => missing, :c => 1)
    @test ComputePipeline.is_same(d, copy(d))
    @test !ComputePipeline.is_same(d, d)
end

@testset "map_latest!" begin
    @testset "Basic functionality" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 1)

        # Simple computation with single input and output
        map_latest!(graph, [:input], [:output]) do x
            return (x * 2,)
        end

        # First call should block until result is ready
        @test graph[:output][] == 2

        # Update and verify it computes the new value
        update!(graph, input = 5)
        graph[:output][] # poll
        sleep(0.1)
        # Force resolution to pick up the new value
        @test graph[:output][] == 10
    end

    @testset "Multiple inputs and outputs" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        add_input!(graph, :b, 2)

        map_latest!(graph, [:a, :b], [:sum, :product]) do a, b
            return (a + b, a * b)
        end

        @test graph[:sum][] == 3
        @test graph[:product][] == 2

        update!(graph, a = 3, b = 4)
        graph[:sum][]  # poll
        sleep(0.3)
        # Check results - these will force resolution
        @test graph[:sum][] == 7
        @test graph[:product][] == 12
    end

    @testset "Skips intermediate updates" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 0)

        computation_count = Ref(0)
        processed_values = Int[]

        map_latest!(graph, [:input], [:output]) do x
            computation_count[] += 1
            push!(processed_values, x)
            sleep(0.2)  # Simulate slow computation
            return (x * 2,)
        end

        # Initialize
        @test graph[:output][] == 0
        @test computation_count[] == 1

        # Rapidly update multiple times
        for i in 1:5
            update!(graph, input = i)
        end

        # Wait for computation to complete
        graph[:output][]  # poll
        sleep(0.5)

        # Access the result - this forces resolution
        result = graph[:output][]

        # Should have processed initial + final value(s), but not all intermediate ones
        @test computation_count[] == 2  # Less than initial + all 5 updates
        @test result == 10  # Final value (5 * 2)
    end

    @testset "Returns previous value while computing" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 1)

        map_latest!(graph, [:input], [:output]) do x
            sleep(0.3)  # Simulate slow computation
            return (x * 10,)
        end

        # Get initial value
        @test graph[:output][] == 10

        # Update with new value
        update!(graph, input = 2)

        # Immediately check - should return previous value while computing
        prev_value = graph[:output][]
        @test prev_value == 10  # Still the old value

        # Wait for computation to finish
        sleep(0.6)

        # Now should have new value
        @test graph[:output][] == 20
    end

    @testset "spawn parameter" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 5)

        # Test with spawn=false (runs on current task)
        map_latest!(graph, [:input], [:output]; spawn = false) do x
            return (x + 1,)
        end

        @test graph[:output][] == 6

        update!(graph, input = 10)
        graph[:output][] # poll
        sleep(0.2)
        @test graph[:output][] == 11
    end

    @testset "Computation updates trigger correctly" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 1)

        update_count = Ref(0)

        map_latest!(graph, [:input], [:output]) do x
            sleep(0.05)
            return (x * 3,)
        end

        # Initialize
        @test graph[:output][] == 3

        # Set up an observable listener to count updates
        obs = ComputePipeline.get_observable!(graph, :output)
        on(obs) do val
            update_count[] += 1
        end

        # Update input
        update!(graph, input = 2)
        sleep(0.3)

        # Should have triggered at least one update
        @test update_count[] >= 1
        @test graph[:output][] == 6
    end
end

@testset "explicit node initialization" begin
    calls = 0
    graph = ComputeGraph()
    add_input!(graph, :x, 1)
    add_input!(graph, :y, 2)
    map!(graph, [:x, :y], [:xy, :yx]) do x, y
        calls += 1
        return (x + y, x - y)
    end
    map!(x -> 2x, graph, :xy, :z)

    @testset "Initial State" begin
        @test isdirty(graph.x)
        @test isdirty(graph.y)
        @test isdirty(graph.xy)
        @test isdirty(graph.yx)
        @test isdirty(graph.z)
    end

    @testset "Partial output init doesn't init edge" begin
        ComputePipeline.unsafe_init!(graph.xy, 1)

        @test isdirty(graph.x)
        @test isdirty(graph.y)
        @test isdirty(graph.xy)
        @test isdirty(graph.yx)
        @test isdirty(graph.z)
        @test ComputePipeline.is_initialized(graph.xy)
        @test !ComputePipeline.is_initialized(graph.yx)
        @test graph.xy.value[] == 1
        @test !isassigned(graph.xy.parent.typed_edge)
        @test calls == 0
    end

    @testset "Partial output init doesn't break normal init" begin
        @test graph.z[] == 6
        @test calls == 1
    end

    calls = 0
    graph = ComputeGraph()
    add_input!(graph, :x, 1)
    add_input!(graph, :y, 2)
    map!(graph, [:x, :y], [:xy, :yx]) do x, y
        calls += 1
        return (x + y, x - y)
    end
    map!(x -> 2x, graph, :xy, :z)
    ComputePipeline.unsafe_init!(graph.xy, 1)

    @testset "Verify reset" begin
        @test isdirty(graph.x)
        @test isdirty(graph.y)
        @test isdirty(graph.xy)
        @test isdirty(graph.yx)
        @test isdirty(graph.z)
        @test ComputePipeline.is_initialized(graph.xy)
        @test !ComputePipeline.is_initialized(graph.yx)
        @test graph.xy.value[] == 1
        @test !isassigned(graph.xy.parent.typed_edge)
        @test calls == 0
    end

    @testset "Full output init does init edge" begin
        ComputePipeline.unsafe_init!(graph.yx, Base.Ref{Any}(2))

        @test !isdirty(graph.x)
        @test !isdirty(graph.y)
        @test !isdirty(graph.xy)
        @test !isdirty(graph.yx)
        @test isdirty(graph.z)
        @test ComputePipeline.is_initialized(graph.xy)
        @test ComputePipeline.is_initialized(graph.yx)
        @test isassigned(graph.xy.parent.typed_edge)
        @test calls == 0
        @test graph.xy.value[] == 1
        @test graph.yx.value[] == 2
        @test calls == 0
        @test !ComputePipeline.is_initialized(graph.z)
        @test graph.z[] == 2
        @test calls == 0
    end

    @testset "updates still work" begin
        graph.x = 2
        @test isdirty(graph.x)
        @test !isdirty(graph.y)
        @test isdirty(graph.xy)
        @test isdirty(graph.z)
        @test calls == 0
        @test graph.xy[] == 4
        @test graph.z[] == 8
        @test calls == 1
    end

    @testset "error on double init" begin
        @test_throws ErrorException ComputePipeline.unsafe_init!(graph.xy, 0)
    end
end

using ComputePipeline: ComputeGraphView

@testset "Nested graphs" begin
    graph = ComputeGraph()

    @testset "Inputs" begin
        add_input!(graph, :a, :a, :a, 1)
        add_input!(graph, (:a, :a, :b), 2)
        add_input!(graph.a, :b, 3)
        add_input!(graph.a, :c, :a, 4)

        @test haskey(graph.inputs, Symbol("a.a.a"))
        @test haskey(graph.inputs, Symbol("a.a.b"))
        @test haskey(graph.inputs, Symbol("a.b"))
        @test haskey(graph.inputs, Symbol("a.c.a"))
        @test graph[Symbol("a.a.a")][] == 1
        @test graph[Symbol("a.a.b")][] == 2
        @test graph[Symbol("a.b")][] == 3
        @test graph[Symbol("a.c.a")][] == 4

        @test graph.outputs[Symbol("a.a.a")].name == Symbol("a.a.a")
        @test graph.outputs[Symbol("a.a.b")].name == Symbol("a.a.b")
        @test graph.outputs[Symbol("a.b")].name == Symbol("a.b")
        @test graph.outputs[Symbol("a.c.a")].name == Symbol("a.c.a")

        @test graph.inputs[Symbol("a.a.a")].name == Symbol("a.a.a")
        @test graph.inputs[Symbol("a.a.b")].name == Symbol("a.a.b")
        @test graph.inputs[Symbol("a.b")].name == Symbol("a.b")
        @test graph.inputs[Symbol("a.c.a")].name == Symbol("a.c.a")

        f(k, v) = v + 1
        add_input!(f, graph, :b, :a, :a, 1)
        add_input!(f, graph, (:b, :a, :b), 2)
        add_input!(f, graph.b, :b, 3)
        add_input!(f, graph.b, :c, :a, 4)

        @test haskey(graph.inputs, Symbol("b.a.a"))
        @test haskey(graph.inputs, Symbol("b.a.b"))
        @test haskey(graph.inputs, Symbol("b.b"))
        @test haskey(graph.inputs, Symbol("b.c.a"))
        @test graph.b.a.a[] == 2
        @test graph.b.a.b[] == 3
        @test graph.b.b[] == 4
        @test graph.b.c.a[] == 5

        add_constant!(graph, :a, :const1, 0)
        @test graph.a.const1[] == 0
        add_constant!(graph, (:a, :const2), 0)
        @test graph.a.const2[] == 0
        add_constant!(graph.a, :const3, 0)
        @test graph.a.const3[] == 0
    end

    @testset "Interfaces" begin
        # a.a.a and a.a.b are one element in graph.a (graph.a.a)
        @test length(graph.a) == 6
        @test length(graph.a.a) == 2
        v = collect(graph.a.a)
        @test length(v) == 2
        @test Pair(:a, graph.a.a.a) in v
        @test Pair(:b, graph.a.a.b) in v

        result1, state = iterate(graph.a.a)
        result2, state = iterate(graph.a.a, state)
        final = iterate(graph.a.a, state)
        @test result1 in v
        @test result2 in v
        @test isnothing(final)

        @test keys(graph.a.a) == Set([:a, :b])
        @test haskey(graph.a, :a)
        @test haskey(graph.a, :a, :a)
        @test haskey(graph.a, :a, :b)
        @test !haskey(graph.a, :a, :c)
        @test haskey(graph.a, :b)
        @test !haskey(graph.a, :d)
        @test !haskey(graph.a, :d, :a, :e)

        N = length(graph.nesting.keytables)
        empty_view = ComputeGraphView(graph, :c)
        @test empty_view.nested_trace.keys == [:c]
        @test empty_view.nested_trace.next_index == N + 1
        @test length(graph.nesting.keytables) == N + 1
        @test isempty(graph.nesting.keytables[N + 1])

        empty_view2 = ComputeGraphView(graph.c, :a)
        @test empty_view2.nested_trace.keys == [:c, :a]
        @test empty_view2.nested_trace.next_index == N + 2
        @test length(graph.nesting.keytables) == N + 2
        @test graph.nesting.keytables[N + 1][:a] == N + 2
        @test isempty(graph.nesting.keytables[N + 2])
    end

    @testset "Access" begin
        @test graph.a isa ComputeGraphView
        @test graph.a.a isa ComputeGraphView
        @test graph.a.a.a isa Computed
        @test graph.a.a.a[] == 1
        @test graph.a.a.b[] == 2
        @test graph.a[].a[].a[] == 1
    end

    @testset "Compute/map!" begin
        # nested nodes -> unnested node
        map!((a, b) -> (a, b), graph, [graph.a.a.a, Symbol("a.a.b")], :x)
        @test graph.x[] == (1, 2)

        graph.a.a.a[] = 5
        graph.a.a.b[] = -1
        @test graph.a.a.a[] == 5
        @test graph.a.a.b[] == -1
        @test graph.x[] == (5, -1)

        # working inside nested view, nested nodes -> nested node
        map!(*, graph.a, [:b, (:c, :a)], :d)
        @test graph.a.d[] == graph.a.b[] * graph.a.c.a[]

        # direct node access should also work outside the view
        map!((a, b) -> (b, a), graph.a, [:b, graph.x], [:swapped_x, :swapped_b], init = ((-1, -1), -2))
        # wrong results from bad init (for testing)
        @test graph.a.swapped_x[] == (-1, -1)
        @test graph.a.swapped_b[] == -2
        graph.a.b = 7
        @test graph.a.swapped_x[] == graph.x[]
        @test graph.a.swapped_b[] == graph.a.b[]

        map!(x -> (x, -x), graph, (:a, :c, :a), [(:a, :c, :plus), (:a, :c, :minus)])
        @test graph.a.c.minus[] == -graph.a.c.a[]
        @test graph.a.c.plus[] == graph.a.c.a[]

        map!(x -> 2x, graph, (:a, :c, :a), :double)
        @test graph.double[] == 2graph.a.c.a[]

        map_latest!(graph.a, [:b], [(:c, :double_b)]) do x
            return (x * 2,)
        end
        @test graph.a.c.double_b[] == 2 * graph.a.b[]

        # names used for callbacks
        add_input!((k, v) -> k === Symbol(:c), graph, :c, 1)
        add_input!((k, v) -> k === Symbol(:d, :(.), :a), graph, :d, :a, 1)
        add_input!((k, v) -> k === Symbol("d.b.c"), graph, :d, :b, :c, 1)
        @test graph.c[]
        @test graph.d.a[]
        @test graph.d.b.c[]

        register_computation!(graph, [(:a, :a, :b), :x], [(:a, :a, :n), :m]) do args, changed, cached
            ks = isnothing(cached) ? (true, true) : (haskey(cached, Symbol("a.a.n")), haskey(cached, :m))
            aab = Symbol("a.a.b")
            return (
                haskey(args, aab) && haskey(changed, aab) && ks[1],
                haskey(args, :x) && haskey(changed, :x) && ks[2],
            )
        end
        @test graph.a.a.n[]
        @test graph.m[]
        graph.a.a.b[] = 99
        @test graph.a.a.n[]
        @test graph.m[]
    end

    @testset "Update" begin
        update!(graph, (:a, :a, :a) => 10)
        @test graph.a.a.a[] == 10
        update!(graph, Dict((:a, :a, :b) => 10))
        @test graph.a.a.b[] == 10
        update!(graph, [(:a, :b) => 10])
        @test graph.a.b[] == 10

        update!(graph.a, (:a, :a) => 12)
        @test graph.a.a.a[] == 12
        update!(graph.a, Dict((:a, :b) => 12))
        @test graph.a.a.b[] == 12
        update!(graph.a, [(:a, :a) => 12])
        @test graph.a.a.a[] == 12

        update!(graph.a, :b => 12)
        @test graph.a.b[] == 12
        update!(graph.a, Dict(:b => 10))
        @test graph.a.b[] == 10
        update!(graph.a, [:b => 9])
        @test graph.a.b[] == 9
        update!(graph.a, b = 13)
        @test graph.a.b[] == 13

        update!(graph.a.c, :a => 12)
        @test graph.a.c.a[] == 12
        update!(graph.a.c, Dict(:a => 10))
        @test graph.a.c.a[] == 10
        update!(graph.a.c, [:a => 9])
        @test graph.a.c.a[] == 9
        update!(graph.a.c, a = 21)
        @test graph.a.c.a[] == 21

        update!(graph.b.a, a = 10)
        graph.b.a.a[] == 11

        graph.b.a.b = 9
        @test graph.b.a.b[] == 10
    end

    # Node is either part of a nesting chain or a value
    @testset "Restrictions" begin
        add_input!(graph, :a, :y, 1)
        @test_throws ErrorException add_input!(graph, :a, :y, :c, 1)
        add_input!(graph, :a, :z, :a, 1)
        @test_throws ErrorException add_input!(graph, :a, :z, 1)
    end
end

@testset "ExplicitUpdate and force_update" begin

    @testset "forced Input update propagation" begin
        graph = ComputeGraph()

        add_input!(graph, :normal, 1)
        add_input!(graph, :forced, 1, force_update = true)
        add_input!((k, v) -> v + 1, graph, :normalf, 1)
        add_input!((k, v) -> v + 1, graph, :forcedf, 1, force_update = true)

        @test graph.normal.parent.force_update == false
        @test graph.forced.parent.force_update == true
        @test graph.normalf.parent.force_update == false
        @test graph.forcedf.parent.force_update == true

        function record_metrics(args, changed, cached)
            metrics = isnothing(cached) ? Tuple{Bool, Int}[] : cached[1]
            push!(metrics, (changed[1], args[1]))
            return (metrics,)
        end

        register_computation!(record_metrics, graph, [:normal], [:normal_metrics])
        register_computation!(record_metrics, graph, [:forced], [:forced_metrics])
        register_computation!(record_metrics, graph, [:normalf], [:normalf_metrics])
        register_computation!(record_metrics, graph, [:forcedf], [:forcedf_metrics])

        @test graph.normal_metrics[] == [(true, 1)]
        @test graph.forced_metrics[] == [(true, 1)]
        @test graph.normalf_metrics[] == [(true, 2)]
        @test graph.forcedf_metrics[] == [(true, 2)]

        update!(graph, :normal => 1, :forced => 1, :normalf => 1, :forcedf => 1)

        @test graph.normal_metrics[] == [(true, 1)]
        @test graph.forced_metrics[] == [(true, 1), (true, 1)]
        @test graph.normalf_metrics[] == [(true, 2)]
        @test graph.forcedf_metrics[] == [(true, 2), (true, 2)]

        update!(graph, :normal => 2, :forced => 2, :normalf => 2, :forcedf => 2)

        @test graph.normal_metrics[] == [(true, 1), (true, 2)]
        @test graph.forced_metrics[] == [(true, 1), (true, 1), (true, 2)]
        @test graph.normalf_metrics[] == [(true, 2), (true, 3)]
        @test graph.forcedf_metrics[] == [(true, 2), (true, 2), (true, 3)]
    end

    @testset "ExplicitUpdate" begin
        graph = ComputeGraph()
        add_input!(graph, :normal, 1)
        add_input!(graph, :forced, 1, force_update = true)
        ComputePipeline.set_type!(graph.normal, Any)
        ComputePipeline.set_type!(graph.forced, Any)

        evaled = Symbol[]

        # passhtrough
        map!(graph, :normal, :normal2) do x
            push!(evaled, :normal2)
            return x
        end
        map!(graph, :forced, :forced2) do x
            push!(evaled, :forced2)
            return x
        end
        ComputePipeline.set_type!(graph.normal2, Any)
        ComputePipeline.set_type!(graph.forced2, Any)

        # Check that set_type!() works
        @test isdefined(graph.normal, :value) && (graph.normal.value isa Base.RefValue{Any})
        @test isdefined(graph.normal2, :value) && (graph.normal2.value isa Base.RefValue{Any})
        @test isdefined(graph.forced, :value) && (graph.forced.value isa Base.RefValue{Any})
        @test isdefined(graph.forced2, :value) && (graph.forced2.value isa Base.RefValue{Any})

        # set in computation
        for source in (:normal, :forced)
            for mode in (:deny, :auto, :force)
                next = Symbol("$(mode)_$(source)")
                final = Symbol("$(mode)_$(source)2")
                map!(graph, source, next) do x
                    push!(evaled, next)
                    return ExplicitUpdate(unwrap_explicit_update(x), mode)
                end
                map!(graph, next, final) do x
                    push!(evaled, final)
                    return x
                end
            end
        end

        # These should always trigger.
        # input.forced -> output.forced always marks output.forced dirty
        # output.forced -> (name in always) always runs but may not propagate further
        always = [:forced2, :deny_forced, :auto_forced, :force_forced]

        # Normal value, not repeated
        @test isempty(evaled)
        @test graph.normal[] == 1
        @test graph.normal2[] == 1
        @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
        @test graph.auto_normal[] == ExplicitUpdate(1, :auto)
        @test graph.force_normal[] == ExplicitUpdate(1, :force)
        @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
        @test graph.auto_normal2[] == ExplicitUpdate(1, :auto)
        @test graph.force_normal2[] == ExplicitUpdate(1, :force)
        @test graph.forced[] == 1
        @test graph.forced2[] == 1
        @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
        @test graph.auto_forced[] == ExplicitUpdate(1, :auto)
        @test graph.force_forced[] == ExplicitUpdate(1, :force)
        @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
        @test graph.auto_forced2[] == ExplicitUpdate(1, :auto)
        @test graph.force_forced2[] == ExplicitUpdate(1, :force)
        @test evaled == [
            :normal2,
            :deny_normal, :auto_normal, :force_normal,
            :deny_normal2, :auto_normal2, :force_normal2,
            always...,
            :deny_forced2, :auto_forced2, :force_forced2,
        ]
        empty!(evaled)

        # Check that set_type!() did not get reset/overwritten
        @test graph.normal.value isa Base.RefValue{Any}
        @test graph.normal2.value isa Base.RefValue{Any}
        @test graph.forced.value isa Base.RefValue{Any}
        @test graph.forced2.value isa Base.RefValue{Any}

        @testset "equal value updates" begin
            # Normal value, repeated
            update!(graph, :normal => 1, :forced => 1)
            @test isempty(evaled)
            @test graph.normal[] == 1
            @test graph.normal2[] == 1
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(1, :force)
            @test graph.forced[] == 1
            @test graph.forced2[] == 1
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced[] == ExplicitUpdate(1, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(1, :force)
            @test evaled == [always..., :force_forced2]
            empty!(evaled)

            # forced update
            # should get through Input, triggering first layer of nodes
            # second layer depends on settings of those updates
            update!(graph, :normal => ExplicitUpdate(1, :force), :forced => ExplicitUpdate(1, :force))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(1, :force)
            @test graph.normal2[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(1, :force)
            @test graph.forced[] == ExplicitUpdate(1, :force)
            @test graph.forced2[] == ExplicitUpdate(1, :force)
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced[] == ExplicitUpdate(1, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(1, :force)
            @test evaled == [
                :normal2,
                :deny_normal, :auto_normal, :force_normal,
                :force_normal2,
                always...,
                :force_forced2,
            ]
            empty!(evaled)

            # auto update - should behave like same value update without ExplicitUpdate
            update!(graph, :normal => ExplicitUpdate(1, :auto), :forced => ExplicitUpdate(1, :auto))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(1, :force) # same inner value, no update
            @test graph.normal2[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(1, :force)
            @test graph.forced[] == ExplicitUpdate(1, :auto) # update forced by Input
            @test graph.forced2[] == ExplicitUpdate(1, :force) # same value with :auto, no update
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced[] == ExplicitUpdate(1, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(1, :force)
            @test evaled == [
                always...,
                :force_forced2,
            ]
            empty!(evaled)

            # deny update - also same as equal value update as those deny
            update!(graph, :normal => ExplicitUpdate(1, :deny), :forced => ExplicitUpdate(1, :deny))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(1, :force) # update denied
            @test graph.normal2[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal[] == ExplicitUpdate(1, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(1, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(1, :force)
            @test graph.forced[] == ExplicitUpdate(1, :deny) # update forced by Input
            @test graph.forced2[] == ExplicitUpdate(1, :force) # update denied
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced[] == ExplicitUpdate(1, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(1, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(1, :force)
            @test evaled == [
                always...,
                :force_forced2,
            ]
            empty!(evaled)
        end

        @testset "Changed value updates" begin
            # Normal value, changed
            update!(graph, :normal => 2, :forced => 2)
            @test isempty(evaled)
            @test graph.normal[] == 2
            @test graph.normal2[] == 2
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny) # update denied by wrapping
            @test graph.auto_normal[] == ExplicitUpdate(2, :auto)
            @test graph.force_normal[] == ExplicitUpdate(2, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(2, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(2, :force)
            @test graph.forced[] == 2
            @test graph.forced2[] == 2
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny) # update denied by wrapping
            @test graph.auto_forced[] == ExplicitUpdate(2, :auto)
            @test graph.force_forced[] == ExplicitUpdate(2, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(2, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(2, :force)
            @test evaled == [
                :normal2,
                :deny_normal, :auto_normal, :force_normal,
                :auto_normal2, :force_normal2,
                always...,
                :auto_forced2, :force_forced2,
            ]
            empty!(evaled)

            # forced update, same as above as different values update
            update!(graph, :normal => ExplicitUpdate(3, :force), :forced => ExplicitUpdate(3, :force))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(3, :force)
            @test graph.normal2[] == ExplicitUpdate(3, :force)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(3, :auto)
            @test graph.force_normal[] == ExplicitUpdate(3, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(3, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(3, :force)
            @test graph.forced[] == ExplicitUpdate(3, :force)
            @test graph.forced2[] == ExplicitUpdate(3, :force)
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(3, :auto)
            @test graph.force_forced[] == ExplicitUpdate(3, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(3, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(3, :force)
            @test evaled == [
                :normal2,
                :deny_normal, :auto_normal, :force_normal,
                :auto_normal2, :force_normal2,
                always...,
                :auto_forced2, :force_forced2,
            ]
            empty!(evaled)

            # auto update - should behave like same value update without ExplicitUpdate
            update!(graph, :normal => ExplicitUpdate(4, :auto), :forced => ExplicitUpdate(4, :auto))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(4, :auto)
            @test graph.normal2[] == ExplicitUpdate(4, :auto)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(4, :auto)
            @test graph.force_normal[] == ExplicitUpdate(4, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(4, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(4, :force)
            @test graph.forced[] == ExplicitUpdate(4, :auto)
            @test graph.forced2[] == ExplicitUpdate(4, :auto)
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(4, :auto)
            @test graph.force_forced[] == ExplicitUpdate(4, :force)
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(4, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(4, :force)
            @test evaled == [
                :normal2,
                :deny_normal, :auto_normal, :force_normal,
                :auto_normal2, :force_normal2,
                always...,
                :auto_forced2, :force_forced2,
            ]
            empty!(evaled)

            # deny update - also same as equal value update as those deny
            update!(graph, :normal => ExplicitUpdate(5, :deny), :forced => ExplicitUpdate(5, :deny))
            @test isempty(evaled)
            @test graph.normal[] == ExplicitUpdate(4, :auto) # update denied
            @test graph.normal2[] == ExplicitUpdate(4, :auto)
            @test graph.deny_normal[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal[] == ExplicitUpdate(4, :auto)
            @test graph.force_normal[] == ExplicitUpdate(4, :force)
            @test graph.deny_normal2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_normal2[] == ExplicitUpdate(4, :auto)
            @test graph.force_normal2[] == ExplicitUpdate(4, :force)
            @test graph.forced[] == ExplicitUpdate(5, :deny) # update forced by Input
            @test graph.forced2[] == ExplicitUpdate(4, :auto) # update denied
            @test graph.deny_forced[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced[] == ExplicitUpdate(5, :auto) # Input forces these to run so that
            @test graph.force_forced[] == ExplicitUpdate(5, :force) # :deny doesn't act before it gets replace
            @test graph.deny_forced2[] == ExplicitUpdate(1, :deny)
            @test graph.auto_forced2[] == ExplicitUpdate(5, :auto)
            @test graph.force_forced2[] == ExplicitUpdate(5, :force)
            @test evaled == [
                always...,
                :auto_forced2, :force_forced2,
            ]
            empty!(evaled)
        end
    end
end
