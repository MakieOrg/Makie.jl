# Individual components

@testset "Graph Initialization" begin
    parent = ComputeGraph()
    add_input!(parent, :in1, 1)
    graph = ComputeGraph()
    add_input!(graph, :in1, parent.in1)
    add_input!(graph, :in2, 2)
    foo(inputs, changed, cached) = (inputs[1][] + inputs[2][],)
    register_computation!(foo, graph, [:in1, :in2], [:merged])

    @testset "Overwrite Errors" begin
        @test_throws ErrorException add_input!(parent, :in1, 1)
        @test_throws ErrorException add_input!(graph, :in1, 1)
        @test_throws ErrorException add_input!(graph, :in2, 1)
        @test_throws ErrorException add_input!(graph, :in1, parent.in1)
        @test_throws ErrorException add_input!(graph, :in2, parent.in1)

        # different inputs, same function = different edge -> error
        @test_throws ErrorException register_computation!(foo, graph, [:in1], [:merged])
        # same inputs, same function = same edge
        @test_logs (:warn, "Identical ComputeEdge already exists. Skipped insertion of new edge") register_computation!(foo, graph, [:in1, :in2], [:merged])
        # same inputs, different function = different edge -> error
        goo(inputs, changed, cached) = (inputs[1][] * inputs[2][],)
        @test_throws ErrorException register_computation!(goo, graph, [:in1, :in2], [:merged])
    end
end

@testset "Graph Interaction" begin
    graph = ComputeGraph()
    add_input!(graph, :in1, 1)
    add_input!(graph, :in2, 2)
    register_computation!(graph, [:in1, :in2], [:merged]) do inputs, changed, cached
        return (inputs[1][] + inputs[2][],)
    end

    # Sanity checks
    @test haskey(graph.inputs, :in1) && haskey(graph.inputs, :in2)
    @test haskey(graph.outputs, :in1) && haskey(graph.outputs, :in2) && haskey(graph.outputs, :merged)

    @testset "Graph Access" begin
        # TODO: These may need some cleanup
        @test graph.in1 === graph.outputs[:in1]
        @test graph.in2 === graph.outputs[:in2]
        @test_throws KeyError graph.merged

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

        @test_throws KeyError graph.merged

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
    foo2(inputs, changed, cached) = (inputs[1][] + inputs[2][], inputs[1][] - inputs[2][])
    register_computation!(foo2, graph, [:in1, :in2], [:added, :subtracted])
    bar(inputs, changed, cached) = (inputs[1][],)
    register_computation!(bar, graph, [:added], [:output])
    register_computation!(bar, graph, [:output], [:output2])
    register_computation!(bar, graph, [:subtracted], [:output3])

    graph[:in1][]

    @testset "brief show()" begin
        # TODO: This counts edges in graph because part of graph continues parent - Should it?
        @test sprint(show, parent) == "ComputeGraph(1 input, 1 output, 4 edges)"
        @test sprint(show, graph) == "ComputeGraph(1 input, 7 outputs, 4 edges)"
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

        @test sprint(show, m, graph[:in1]) == "Computed:\n  name = :in1\n  parent = Input(:in1, 1)\n  value = 1"
        @test sprint(show, m, graph[:in2]) == "Computed:\n  name = :in2\n  parent = Input(:in2, 2)\n  value = #undef"

        s = sprint(show, m, graph[:added].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    foo2(::Tuple{Ref{Int64}, Ref{Any}}, ::Vector{Bool}, ::Nothing)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:in1, 1)\n    ↻ Computed(:in2, #undef)\n  outputs:\n    ↻ Computed(:added, #undef)\n    ↻ Computed(:subtracted, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 1 dependent)\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    bar(::Tuple, ::Vector{Bool}, ::Nothing)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:added, #undef)\n  outputs:\n    ↻ Computed(:output, #undef)\n  dependents:\n    ↻ ComputeEdge(bar(…), 1 input, 1 output, 0 dependents)")

        s = sprint(show, m, graph[:output2].parent)
        @test contains(s, "ComputeEdge:\n  callback:\n    bar(::Tuple, ::Vector{Bool}, ::Nothing)\n    @ ")
        @test contains(s, "\n  inputs:\n    ↻ Computed(:output, #undef)\n  outputs:\n    ↻ Computed(:output2, #undef)\n  dependents:")
    end
end