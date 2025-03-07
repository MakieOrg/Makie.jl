# Individual components

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

