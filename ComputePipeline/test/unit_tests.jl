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
        # TODO: These may need some cleanup
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
        @test get_state(graph) == [1,0,1,0,1]
        @test graph[:merged][] == 7

        @test_throws ErrorException update!(graph, merged = 2)
        @test get_state(graph) == [0,0,0,0,0]
        @test graph[:merged][] == 7

        update!(graph, in2 = 4, in1 = 7)
        @test get_state(graph) == [1,1,1,1,1]
        @test graph[:merged][] == 11

        graph.in2 = 0
        @test graph.inputs[:in2].value[] == 0
        @test get_state(graph) == [0,1,0,1,1]
        @test graph[:merged][] == 7

        graph.in1[] = 3
        @test graph.inputs[:in1].value[] == 3
        @test graph.outputs[:in1].value[] == 7
        @test get_state(graph) == [1,0,1,0,1]
        @test graph[:merged][] == 3
    end

    @testset "Graph resolve" begin
        update!(graph, in1 = 2, in2 = 1)
        @test get_state(graph) == [1,1,1,1,1]
        @test graph.inputs[:in1].value[] == 2
        @test graph.inputs[:in2].value[] == 1
        @test graph.outputs[:in1].value[] == 3
        @test graph.outputs[:in2].value[] == 0

        # getproperty interface
        @test graph.in1[] == 2
        @test graph.outputs[:in1].value[] == 2
        @test get_state(graph) == [0,1,0,1,1]

        @test graph.in2[] == 1
        @test graph.outputs[:in2].value[] == 1
        @test get_state(graph) == [0,0,0,0,1]

        @test graph.merged === graph.outputs[:merged]

        update!(graph, in1 = -1, in2 = -2)
        @test get_state(graph) == [1,1,1,1,1]
        @test graph.inputs[:in1].value[] == -1
        @test graph.inputs[:in2].value[] == -2
        @test graph.outputs[:in1].value[] == 2
        @test graph.outputs[:in2].value[] == 1

        # getindex interface
        @test graph[:in1][] == -1
        @test graph.outputs[:in1].value[] == -1
        @test get_state(graph) == [0,1,0,1,1]

        @test graph[:in2][] == -2
        @test graph.outputs[:in2].value[] == -2
        @test get_state(graph) == [0,0,0,0,1]

        # verify that this isn't a multi-step resolve
        graph.inputs[:in1].value = 7

        @test graph[:merged][] == -3
        @test graph.outputs[:merged].value[] == -3
        @test get_state(graph) == [0,0,0,0,0]

        # verify with parent being another compute edge too
        register_computation!(graph, [:merged], [:output]) do inputs, changed, cached
            return (inputs[1][],)
        end
        graph.outputs[:in1].value[] = 12
        @test graph[:output][] == -3
        @test graph.outputs[:output].value[] == -3
        @test get_state(graph) == [0,0,0,0,0]
        @test !isdirty(graph[:output])

        # multi-step with compute edge
        update!(graph, in1 = 10)
        @test get_state(graph) == [1,0,1,0,1]
        @test isdirty(graph[:output])
        @test graph[:output][] == 8
        @test graph.outputs[:output].value[] == 8
        @test get_state(graph) == [0,0,0,0,0]
        @test !isdirty(graph[:output])
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

        s = sprint(show, m, graph[:added].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    foo2(::@NamedTuple{}, ::@NamedTuple{}, ::Nothing)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:in1, 1)\n    ↻ Computed(:in2, #undef)\n  outputs:\n    ↻ Computed(:added, #undef)\n    ↻ Computed(:subtracted, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 1 dependent)\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    bar(::@NamedTuple{}, ::@NamedTuple{}, ::Nothing)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:added, #undef)\n  outputs:\n    ↻ Computed(:output, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output2].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    bar(::@NamedTuple{}, ::@NamedTuple{}, ::Nothing)\n    @ ")
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

        @test begin delete!(graph, :out); true end
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
        register_computation!(g, [:input1, :input2], [:xy, :yx]) do (x,y), changed, cached
            return ([x; y], [y; x])
        end
        map!(x -> [x; 1], g, :xy, :out1)
        map!(x -> [x; 1], g, :yx, :out2)
        map!((x,y) -> tuple.(x,y), g, [:out1, :out2], :zipped)
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
            @test g.observables[:zipped][] == [(0f0, 1f0), (1f0, 0f0), (1f0, 1f0)]
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
        add_input!((k, x) -> Float64.(x), g, :input1, 1)
        add_input!((k, x) -> Float64.(x), g, :input2, 4)
        register_computation!(g, [:input1, :input2], [:xy, :yx]) do (x,y), changed, cached
            return (x-y, y-x)
        end
        map!(x -> x + 1, g, :xy, :out1)
        map!(x -> x + 1, g, :yx, :out2)
        map!((x,y) -> x * y, g, [:out1, :out2], :mult)

        @test isempty(g.observables)

        obs = Observable{Any}()
        on(x -> obs[] = x, g[:mult])
        @test_throws UndefRefError obs[]
        @test haskey(g.observables, :mult)
        @test length(g.observables) == 1

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
        ComputePipeline.update!(g, input1 = 2, input2 = 5)
        @test counter[] == 4

    end
end