@testset "Full System Test" begin
    parent = ComputeGraph()
    add_input!(parent, :pin1, 1)
    add_input!(parent, :pin2, nothing)
    f32(x) = Float32.(x) # wrong on purpose
    add_input!(f32, parent, :pin3, [1, 2, 3])

    foo1((i, v), changed, outputs) = (v .- i, v .+ i)
    register_computation!(foo1, parent, [:pin1, :pin3], [:pout1, :pout3])

    foo2((x, i), changed, outputs) = (string(x, i),)
    register_computation!(foo2, parent, [:pin2, :pin1], [:pout2])

    @testset "Parent initialization" begin

        # Note:
        # These tests explicitly avoid checking dirty/resolved state and values of
        # output nodes because they are technically undefined at this point. They
        # are checked once the state of the graph is clear, i.e. after resolving
        # and updating.

        @testset "Inputs" begin
            @test length(parent.inputs) == 3

            for (name, val) in [(:pin1, 1), (:pin2, nothing), (:pin3, [1, 2, 3])]
                @test haskey(parent.inputs, name)
                @test haskey(parent.outputs, name)

                x = parent.inputs[name]
                @test x.name === name
                @test x.value == val
                @test x.output === parent.outputs[name]
                @test parent.outputs[name].parent === x
                @test parent.outputs[name].parent_idx == 1
            end

            @test parent.inputs[:pin1].f === identity
            @test parent.inputs[:pin2].f === identity
            @test parent.inputs[:pin3].f === InputFunctionWrapper(:pin3, f32)
        end

        @testset "Outputs" begin
            @test length(parent.outputs) == 6

            for name in [:pin1, :pin2, :pin3, :pout1, :pout2, :pout3]
                @test parent.outputs[name].name === name
            end
        end

        @testset "Structure/Edges" begin
            e1 = parent.outputs[:pout1].parent
            e2 = parent.outputs[:pout2].parent
            e3 = parent.outputs[:pout3].parent

            @test e1 === e3
            @test e1.callback === foo1
            @test isempty(e1.dependents)
            @test e1.inputs == [parent.outputs[:pin1], parent.outputs[:pin3]]
            @test e1.outputs == [parent.outputs[:pout1], parent.outputs[:pout3]]

            @test e2.callback === foo2
            @test isempty(e2.dependents)
            @test e2.inputs == [parent.outputs[:pin2], parent.outputs[:pin1]]
            @test e2.outputs == [parent.outputs[:pout2]]
        end
    end


    graph = ComputeGraph()
    add_input!(graph, :in1, 1)
    to_float(k, v) = Float32(v)
    add_input!(to_float, graph, :in2, 1)
    add_input!(graph, :in3, sin)
    add_input!(graph, :in4, :test)
    add_input!(graph, :trans2, parent[:pout2])
    to_int(k, x) = Int64.(x)
    add_input!(to_int, graph, :trans1, parent[:pout1])
    add_input!(to_int, graph, :trans3, parent[:pout3])

    reflect_inputs(inputs, changed, cached) = (values(inputs),)
    register_computation!(reflect_inputs, graph, [:in3, :in2, :in4], [:inputs324])

    reflect_changed(inputs, changed, cached) = (changed,)
    register_computation!(reflect_changed, graph, [:in1, :in3, :in2, :in4], [:changed1324])

    reflect_cached(inputs, changed, cached) = cached === nothing ? (rand(Int),) : (cached[1],)
    register_computation!(reflect_cached, graph, [:in1, :in4], [:cached14])

    discard(inputs, changed, outputs) = inputs[:in1] < 10 ? nothing : (inputs[1],)
    register_computation!(discard, graph, [:in1], [:discard10])

    merge_data(inputs, changed, outputs) = (inputs[1] .+ inputs[2],)
    register_computation!(merge_data, graph, [:trans1, :trans3], [:merged])


    @testset "Child initialization" begin
        @testset "Parent Graph Changes" begin
            e1 = parent.outputs[:pout1].parent
            e2 = parent.outputs[:pout2].parent

            @test length(e1.dependents) == 2
            @test length(e2.dependents) == 1
            @test e1.dependents[1] === graph.outputs[:trans1].parent
            @test e1.dependents[2] === graph.outputs[:trans3].parent
            @test e2.dependents[1] === graph.outputs[:trans2].parent
        end

        @testset "Inputs" begin
            @test length(graph.inputs) == 4

            for (name, val) in [(:in1, 1), (:in2, 1), (:in3, sin), (:in4, :test)]
                @test haskey(graph.inputs, name)
                @test haskey(graph.outputs, name)

                x = graph.inputs[name]
                @test x.name === name
                @test x.value == val
                @test x.output === graph.outputs[name]
                @test graph.outputs[name].parent === x
                @test graph.outputs[name].parent_idx == 1
            end

            @test graph.inputs[:in1].f === identity
            @test graph.inputs[:in2].f === InputFunctionWrapper(:in2, to_float)
            @test graph.inputs[:in3].f === identity
            @test graph.inputs[:in4].f === identity
        end

        output_names = [
            :in1, :in2, :in3, :in4,
            :trans1, :trans2, :trans3,
            :inputs324, :changed1324, :cached14, :discard10, :merged,
        ]

        @testset "Outputs" begin
            @test length(graph.outputs) == 12

            for name in output_names
                @test graph.outputs[name].name === name
            end
        end

        @testset "Structure/Edges" begin
            edges = [graph.outputs[name].parent for name in output_names]

            for i in 1:4
                @test edges[i] === graph.inputs[Symbol(:in, i)]
            end

            @test edges[5].callback === InputFunctionWrapper(:trans1, to_int)
            @test edges[5].dependents == [edges[12]]
            @test edges[5].inputs == [parent.outputs[:pout1]]
            @test edges[5].outputs == [graph.outputs[:trans1]]

            @test edges[6].callback === ComputePipeline.compute_identity
            @test isempty(edges[6].dependents)
            @test edges[6].inputs == [parent.outputs[:pout2]]
            @test edges[6].outputs == [graph.outputs[:trans2]]

            @test edges[7].callback === InputFunctionWrapper(:trans3, to_int)
            @test edges[7].dependents == [edges[12]]
            @test edges[7].inputs == [parent.outputs[:pout3]]
            @test edges[7].outputs == [graph.outputs[:trans3]]

            @test edges[8].callback === reflect_inputs
            @test isempty(edges[8].dependents)
            @test edges[8].inputs == getindex.(Ref(graph.outputs), [:in3, :in2, :in4])
            @test edges[8].outputs == [graph.outputs[:inputs324]]

            @test edges[9].callback === reflect_changed
            @test isempty(edges[9].dependents)
            @test edges[9].inputs == getindex.(Ref(graph.outputs), [:in1, :in3, :in2, :in4])
            @test edges[9].outputs == [graph.outputs[:changed1324]]

            @test edges[10].callback === reflect_cached
            @test isempty(edges[10].dependents)
            @test edges[10].inputs == getindex.(Ref(graph.outputs), [:in1, :in4])
            @test edges[10].outputs == [graph.outputs[:cached14]]

            @test edges[11].callback === discard
            @test isempty(edges[11].dependents)
            @test edges[11].inputs == [graph.outputs[:in1]]
            @test edges[11].outputs == [graph.outputs[:discard10]]

            @test edges[12].callback === merge_data
            @test isempty(edges[12].dependents)
            @test edges[12].inputs == getindex.(Ref(graph.outputs), [:trans1, :trans3])
            @test edges[12].outputs == [graph.outputs[:merged]]
        end
    end


    @testset "Updates" begin

        # Checking parents explicitly so code changes in node.parent and edge.inputs do
        # get caught

        # test initial state -> resolved state
        @testset "parent graph resolve state" begin
            @test parent[:pout2][] == "nothing1" # resolve
            @test !isdirty(parent.outputs[:pout2])
            @test !isdirty(parent.outputs[:pin1])
            @test !isdirty(parent.outputs[:pin2])
            @test !isdirty(parent.inputs[:pin1])
            @test !isdirty(parent.inputs[:pin2])
            @test parent.outputs[:pout2].value[] == "nothing1" # read
            @test parent.outputs[:pin1].value[] == 1
            @test parent.outputs[:pin2].value[] === nothing

            # Does not update child node
            @test isdirty(graph.outputs[:trans2])
        end

    end

    # graph & parent
    @test_throws ResolveException graph[:merged][] == [2, 4, 6]
    # needs to be in the same scope as previous f32 definition
    f32(key, x) = Float32.(x)

    @testset "Updates continued" begin

        @testset "child graph resolve state" begin
            @test graph.outputs[:merged][] == [2, 4, 6]
            @test !isdirty(graph.outputs[:trans1])
            @test !isdirty(graph.outputs[:trans3])
            @test !isdirty(parent.outputs[:pout1])
            @test !isdirty(parent.outputs[:pout3])
            @test !isdirty(parent.outputs[:pin3])
            @test graph.outputs[:trans1].value[] == Int64[0, 1, 2]
            @test graph.outputs[:trans3].value[] == Int64[2, 3, 4]
            @test parent.outputs[:pout1].value[] == Float32[0, 1, 2]
            @test parent.outputs[:pout3].value[] == Float32[2, 3, 4]
            @test parent.outputs[:pin3].value[] == Float32[1, 2, 3]
        end

        @testset "callback function" begin
            # check reflection nodes for correct inputs, changed, cached
            @test graph[:inputs324][] == (graph[:in3].value[], graph[:in2].value[], graph[:in4].value[])
            @test graph[:changed1324][] == (in1 = true, in3 = true, in2 = true, in4 = true)
            # If all are unchanged the update is skipped entirely so this is expected:
            @test graph[:changed1324][] == (in1 = true, in3 = true, in2 = true, in4 = true)
        end

        init = graph[:cached14][]

        # test resolved state -> dirty state
        @testset "update/dirty propagation" begin
            for v in values(parent.inputs)
                @test !isdirty(v)
            end
            for v in values(parent.outputs)
                @test !isdirty(v)
            end
            for v in values(graph.inputs)
                @test !isdirty(v)
            end
            for key in keys(graph.outputs)
                @test isdirty(graph.outputs[key]) == in(key, (:trans2, :discard10))
            end

            update!(graph, in1 = 11)
            @test isdirty(graph.inputs[:in1])
            @test isdirty(graph.outputs[:in1])
            @test isdirty(graph.outputs[:cached14])
            @test isdirty(graph.outputs[:changed1324])

            update!(parent, pin3 = [3, 2, 1])
            @test isdirty(parent.inputs[:pin3])
            @test isdirty(parent.outputs[:pin3])
            @test isdirty(parent.outputs[:pout1])
            @test isdirty(parent.outputs[:pout3])
            @test isdirty(graph.outputs[:trans1])
            @test isdirty(graph.outputs[:trans3])
            @test isdirty(graph.outputs[:merged])
        end

        # Since we didn't assume anything about the initial resolve/dirty state we
        # should tests dirty -> resolved state:
        @testset "child resolve after invalidation" begin
            # partial
            @test graph[:trans3][] == [4, 3, 2]
            @test !isdirty(graph.outputs[:trans3])
            @test !isdirty(parent.outputs[:pout3])
            @test !isdirty(parent.outputs[:pout1]) # same edge as pout3, so updated with pout3
            @test !isdirty(parent.outputs[:pin3])
            @test !isdirty(parent.inputs[:pin3])

            @test isdirty(graph.outputs[:trans1])
            @test isdirty(graph.outputs[:merged])

            # the rest
            @test graph[:merged][] == [6, 4, 2]
            @test !isdirty(graph.outputs[:merged])
            @test !isdirty(graph.outputs[:trans1])
            @test !isdirty(graph.outputs[:trans3])
            @test !isdirty(parent.outputs[:pout3])
            @test !isdirty(parent.outputs[:pout1]) # same edge as pout3
            @test !isdirty(parent.outputs[:pin3])
            @test !isdirty(parent.inputs[:pin3])
        end

        @testset "callback function" begin
            @test graph[:changed1324][] == (in1 = true, in3 = false, in2 = false, in4 = false)
            @test graph[:cached14][] == init
            @test graph[:discard10][] == 11
            update!(graph, in1 = 2)
            @test graph[:discard10][] == 11
            update!(graph, in1 = 22, in4 = :foo)
            @test graph[:discard10][] == 22
            @test graph[:cached14][] == init
            @test graph[:changed1324][] == (in1 = true, in3 = false, in2 = false, in4 = true)
            update!(graph, in2 = 0)
            @test graph[:changed1324][] == (in1 = false, in3 = false, in2 = true, in4 = false)
        end

    end
end
