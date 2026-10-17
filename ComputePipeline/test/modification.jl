function test_disconnected_edge(new, prev; dependents = prev.dependents)
    @assert new !== prev

    @test new.graph == prev.graph
    @test new.callback == ComputePipeline.invalid_callback
    @test isempty(new.inputs)
    @test isempty(new.inputs_dirty)
    @test new.got_resolved[] == true
    @test new.dependents == dependents
    @test !isassigned(new.typed_edge)
    if prev isa ComputePipeline.ComputeEdge
        @test new.outputs == prev.outputs
        for input in prev.inputs
            @test !in(new, input.parent.dependents)
            @test !in(prev, input.parent.dependents)
        end
    end
    return
end

@testset "deletion" begin
    foo(inputs, changed, cached) = (inputs[1],)
    foo2(inputs, changed, cached) = (inputs[1] + inputs[2], inputs[1] - inputs[2])

    @testset "public interface" begin
        graph = ComputeGraph()
        add_input!(graph, :in, 1)
        register_computation!(foo, graph, [:in], [:out])
        register_computation!(foo, graph, [:in], [:out2])

        # These should not be available
        @test_throws MethodError delete!(graph, graph.inputs[:in]) # Input
        @test_throws MethodError delete!(graph, graph.outputs[:in]) # Computed
        @test_throws MethodError delete!(graph, graph.outputs[:out].parent) # ComputeEdge

        @test_throws KeyError delete!(graph, :unknown)

        @test begin
            delete!(graph, :out); true
        end
        @test begin
            delete!(graph.out2.parent); true
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

    @testset "Edge" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 1)
        map!(x -> (x, x), graph, :input, [:a, :b])
        map!(identity, graph, :a, :out1)
        map!(identity, graph, :b, :out2)
        map!(+, graph, [:out1, :out2], :final)

        @test graph.out1[] == 1

        e = graph.out1.parent
        @test e.graph == graph
        @test e.callback == ComputePipeline.MapFunctionWrapper(identity)
        @test e.inputs == [graph.a]
        @test e.inputs_dirty == [false]
        @test e.outputs == [graph.out1]
        @test e.got_resolved[] == true
        @test e.dependents == [graph.final.parent]
        @test isassigned(e.typed_edge)
        @test graph.a.parent.dependents == [e, graph.out2.parent]
        @test graph.out1.parent === e

        delete!(e)
        @test graph.out1[] == 1 # no error
        @test graph.final[] == 2

        # Node now acts as a constant, i.e. has an edge with no inputs that
        # stays resolved.
        @test graph.out1.parent !== e
        new = graph.out1.parent
        test_disconnected_edge(new, e)

        # The edge should not become dirty by normal means
        graph.input = 2
        @test new.got_resolved[] == true
        @test graph.out1[] == 1
        @test graph.final[] == 3

        # Forcing it to be dirty through irregular means should trigger an error
        ComputePipeline.mark_dirty!(graph.out1)
        @test new.got_resolved[] == false # condition for test
        @test_throws ComputePipeline.ResolveException{ErrorException} graph.out1[]

        # restore for future tests
        ComputePipeline.mark_resolved!(graph.out1)
        graph.final[]

        # Test internal functions too
        @testset "Internals" begin
            e = graph.out2.parent
            @test e.graph == graph
            @test e.callback == ComputePipeline.MapFunctionWrapper(identity)
            @test e.inputs == [graph.b]
            @test e.inputs_dirty == [false]
            @test e.outputs == [graph.out2]
            @test e.got_resolved[] == true
            @test e.dependents == [graph.final.parent]
            @test isassigned(e.typed_edge)
            @test graph.a.parent.dependents == [e]
            @test graph.out2.parent === e

            # This should remove from dependents only
            ComputePipeline._disconnect_edge_from_inputs!(e)
            @test e.graph == graph
            @test e.callback == ComputePipeline.MapFunctionWrapper(identity)
            @test e.inputs == [graph.b]
            @test e.inputs_dirty == [false]
            @test e.outputs == [graph.out2]
            @test e.got_resolved[] == true
            @test e.dependents == [graph.final.parent]
            @test isassigned(e.typed_edge)
            @test isempty(graph.a.parent.dependents)
            @test graph.out2.parent === e

            # This should disconnect the edge from an output node
            ComputePipeline._disconnect_node_from_parent!(graph.out2)
            @test graph.out2.parent !== e
            new = graph.out2.parent
            test_disconnected_edge(new, e)
        end

        # Test with multiple outputs
        e = graph.final.parent
        @test e.graph == graph
        @test e.callback == ComputePipeline.MapFunctionWrapper(+)
        @test e.inputs == [graph.out1, graph.out2]
        @test e.inputs_dirty == [false, false]
        @test e.outputs == [graph.final]
        @test e.got_resolved[] == true
        @test isempty(e.dependents)
        @test isassigned(e.typed_edge)
        @test graph.out1.parent.dependents == [e]
        @test graph.out2.parent.dependents == [e]
        @test graph.final.parent === e

        delete!(e)
        @test graph.final[] == 3

        @test graph.final.parent !== e
        new = graph.final.parent
        test_disconnected_edge(new, e)
    end

    # Deletes connections from one graph to any parent and any child graph
    @testset "disconnect!" begin
        p1 = ComputeGraph()
        add_input!(p1, :a, 1)
        add_input!(p1, :b, 1)
        add_input!(p1, :c, 1)

        p2 = ComputeGraph()
        add_input!(p2, :a, 1)
        add_input!(p2, :b, 1)
        add_input!(p2, :c, 1)

        graph = ComputeGraph()
        add_input!(graph, :p1a, p1.a)
        map!(identity, graph, p1.b, :p1b)
        map!(+, graph, [p2.a, p2.b], :p2ab)
        map!(+, graph, [p1.c, p2.c], :p12c)

        map!(+, graph, [:p1a, :p1b], :p1ab)
        add_input!(graph, :x, 1)
        map!(identity, graph, :x, :y)
        map!(+, graph, [:p1ab, :p2ab, :y], :z)

        c1 = ComputeGraph()
        add_input!(c1, :gp12c, graph.p12c)
        map!(identity, c1, graph.z, :z)
        add_input!(c1, :c, p1.c)

        c2 = ComputeGraph()
        map!(+, c2, [graph.z, p2.c], :zc)
        map!(+, c2, [p1.c, p2.c], :c)

        # parent -> graph
        e_p1a = graph.p1a.parent
        e_p1b = graph.p1b.parent
        e_p2ab = graph.p2ab.parent
        e_p12c = graph.p12c.parent

        # graph -> child
        e_gp12c = c1.gp12c.parent
        e_z = c1.z.parent

        # Mixed source (graph and p2)
        e_zc = c2.zc.parent

        # parent -> child
        e_c1 = c1.c.parent
        e_c2 = c2.c.parent

        # graph internal
        e_p1ab = graph.p1ab.parent
        e_y = graph.y.parent
        g_e_z = graph.z.parent

        # Validate initial state / graph crossings
        @test e_p1a.graph == graph
        @test only(e_p1a.inputs) == p1.a
        @test e_p1b.graph == graph
        @test only(e_p1b.inputs) == p1.b
        @test e_p2ab.graph == graph
        @test e_p2ab.inputs == [p2.a, p2.b]
        @test e_p12c.graph == graph
        @test e_p12c.inputs == [p1.c, p2.c]

        @test only(graph.p12c.parent.dependents) == e_gp12c
        @test graph.z.parent.dependents == [e_z, e_zc]

        @test only(e_c1.inputs) == p1.c
        @test e_c2.inputs == [p1.c, p2.c]

        ComputePipeline.disconnect!(graph)

        # Test disconnected parents -> graph
        test_disconnected_edge(graph.p1a.parent, e_p1a)
        test_disconnected_edge(graph.p1b.parent, e_p1b)
        test_disconnected_edge(graph.p2ab.parent, e_p2ab)
        test_disconnected_edge(graph.p12c.parent, e_p12c, dependents = ComputePipeline.ComputeEdge{ComputeGraph}[])

        # Test disconnected graph -> children
        test_disconnected_edge(c1.gp12c.parent, e_gp12c)
        test_disconnected_edge(c1.z.parent, e_z)

        # Mixed
        @test e_zc !== c2.zc.parent
        @test c2.zc.parent.inputs[1][] == 5 # dummy that should be resolvable to the last value of graph.z
        @test c2.zc.parent.inputs[2] == p2.c
        @test isempty(graph.z.parent.dependents)

        # Test preserved
        @test e_c1 === c1.c.parent
        @test e_c2 === c2.c.parent
        @test e_p1ab === graph.p1ab.parent
        @test e_y === graph.y.parent
        @test g_e_z === graph.z.parent
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

@testset "Loop Checks" begin
    # This should be difficult to construct
    let
        graph = ComputeGraph()
        graph.outputs[:a] = ComputePipeline.Computed(:a)
        @test_throws ErrorException map!(identity, graph, :a, :b)
    end

    graph = ComputeGraph()
    add_input!(graph, :a, 1)
    map!(identity, graph, :a, :b)
    map!(identity, graph, :b, :c)
    map!(identity, graph, :c, :d)
    singles = (graph.a, graph.b, graph.c, graph.d)

    g1 = ComputeGraph()
    add_input!(g1, :a, 1)
    g2 = ComputeGraph()
    map!(identity, g2, g1.a, :b)
    g3 = ComputeGraph()
    map!(identity, g3, g2.b, :c)
    map!(identity, g1, g3.c, :d)
    multis = (g1.a, g2.b, g3.c, g1.d)

    for (nodes, name) in ((singles, "Single"), (multis, "Multi"))
        @testset "$name Graph" begin
            a, b, c, d = nodes

            @testset "is_child_of (normal)" begin
                # is_child_of(node, node) is undefined
                @test ComputePipeline.is_child_of(b, a)
                @test ComputePipeline.is_child_of(c, a)
                @test ComputePipeline.is_child_of(d, a)

                @test !ComputePipeline.is_child_of(a, b)
                @test ComputePipeline.is_child_of(c, b)
                @test ComputePipeline.is_child_of(d, b)

                @test !ComputePipeline.is_child_of(a, c)
                @test !ComputePipeline.is_child_of(b, c)
                @test ComputePipeline.is_child_of(d, c)

                @test !ComputePipeline.is_child_of(a, d)
                @test !ComputePipeline.is_child_of(b, d)
                @test !ComputePipeline.is_child_of(c, d)
            end

            @testset "is_part_of_loop" begin
                @test !ComputePipeline.is_part_of_loop(a)
                @test !ComputePipeline.is_part_of_loop(b)
                @test !ComputePipeline.is_part_of_loop(c)
                @test !ComputePipeline.is_part_of_loop(d)
            end

            a[]

            a.parent = d.parent
            # a now has an edge c -> d with no further dependents
            # b -> c still has this edge as a dependent
            # change output to a
            a.parent.outputs[1] = a
            # close the dependents loop
            push!(a.parent.dependents, b.parent)

            # verify loops in both directions
            start = a
            parent = only(a.parent.inputs)
            @test parent === c
            parent = only(parent.parent.inputs)
            @test parent === b
            parent = only(parent.parent.inputs)
            @test parent === a

            e = only(a.parent.dependents)
            @test only(e.outputs) === b
            e = only(e.dependents)
            @test only(e.outputs) === c
            e = only(e.dependents)
            @test only(e.outputs) === a

            # is_child_of is meant as a way to detect loops before they are created, so
            # this is a bit pointless...
            @testset "is_child_of (looped)" begin
                @test ComputePipeline.is_child_of(b, a)
                @test ComputePipeline.is_child_of(c, a)

                @test ComputePipeline.is_child_of(a, b)
                @test ComputePipeline.is_child_of(c, b)

                @test ComputePipeline.is_child_of(a, c)
                @test ComputePipeline.is_child_of(b, c)
            end

            @testset "is_part_of_loop" begin
                @test ComputePipeline.is_part_of_loop(a)
                @test ComputePipeline.is_part_of_loop(b)
                @test ComputePipeline.is_part_of_loop(c)
            end
        end
    end
end

@testset "Edge Modification" begin
    graph = ComputeGraph()
    add_input!(+, graph, :a, 1)
    add_input!(graph, :b, 2)
    add_input!(graph, :c, 3)

    map!(+, graph, :a, :x)

    @test graph.x[] == 1

    @testset "ComputeEdge" begin
        @testset "callback" begin
            # switch to register_computation! style
            ComputePipeline.modify_edge!(
                graph.x.parent, wrap_callback = false,
                callback = (inputs, changed, cached) -> (-inputs[1],)
            )
            @test graph.x[] == -1

            # switch back
            ComputePipeline.modify_edge!(graph.x.parent, wrap_callback = true, callback = +)
            @test graph.x[] == 1
        end

        @testset "Edge Inputs" begin
            ComputePipeline.modify_edge!(graph.x.parent, inputs = [graph.b])
            @test graph.x[] == 2

            ComputePipeline.modify_edge!(graph.x.parent, inputs = [graph.a, graph.c])
            @test graph.x[] == 4
        end

        @testset "Edge Outputs" begin
            # This node is a placeholder for modify_edge!
            ComputePipeline.add_orphaned_node!(graph, :y)
            @test haskey(graph, :y)
            @test_throws ComputePipeline.ResolveException graph.y[]

            prev_edge = graph.x.parent
            ComputePipeline.modify_edge!(graph.x.parent, outputs = [graph.y])
            @test graph.y[] == 4
            @test graph.x[] == 4
            test_disconnected_edge(graph.x.parent, prev_edge)
            graph.a = -1
            @test graph.y[] == 2
            @test graph.x[] == 4

            ComputePipeline.modify_edge!(
                graph.y.parent,
                callback = (a, b) -> (a, b),
                outputs = [graph.x, graph.y]
            )
            @test graph.x[] == -1
            @test graph.y[] == 3
        end

        # replace, delete, push
        @testset "replace, delete and push" begin
            # TODO: Does this ever make sense without a callback change?
            ComputePipeline.delete_output!(graph.x.parent, graph.y)
            ComputePipeline.modify_edge!(graph.x.parent, callback = +, wrap_callback = true)
            graph.a = 1
            @test graph.x[] == 4
            @test graph.y[] == 3

            ComputePipeline.replace_output!(graph.x.parent, :x => :y)
            graph.a = -1
            @test graph.x[] == 4
            @test graph.y[] == 2

            # Loop checks
            @test_throws ErrorException ComputePipeline.replace_output!(graph.x.parent, :y => :a)
            map!(identity, graph, :y, :z)
            @test_throws ErrorException ComputePipeline.replace_output!(graph.z.parent, :z => :a)

            ComputePipeline.push_input!(graph.y.parent, graph.b)
            @test graph.y[] == 4
            graph.b = 5
            @test graph.y[] == 7

            ComputePipeline.delete_input!(graph.y.parent, graph.c)
            @test graph.y[] == 4
        end
    end

    @testset "Input Edge" begin
        @testset "callback" begin
            ComputePipeline.modify_edge!(graph.a.parent, callback = -)
            @test graph.a[] == -graph.inputs[:a].value

            # switch back
            ComputePipeline.modify_edge!(graph.b.parent, callback = -)
            @test graph.b[] == -5
        end

        @testset "Edge Output" begin
            ComputePipeline.add_orphaned_node!(graph, :_c)

            old_deps = copy(graph.c.parent.dependents)
            ComputePipeline.modify_edge!(graph.c.parent, output = graph._c)
            @test graph.c[] == 3
            @test graph._c[] == 3
            graph.c = 5
            @test graph.c[] == 3
            @test graph._c[] == 5
            test_disconnected_edge(graph.c.parent, graph._c.parent, dependents = old_deps)
            @test graph.c.parent.outputs == [graph.c]

            # restore
            ComputePipeline.modify_edge!(graph._c.parent, output = graph.c)
            graph.c = 4
            @test graph.c[] == 4
            @test graph._c[] == 5
        end

        @testset "replace" begin
            ComputePipeline.replace_output!(graph.c.parent, :c => :_c)
            graph.c = 3
            @test graph.c[] == 4
            @test graph._c[] == 3
        end
    end
end

@testset "move!" begin
    graph = ComputeGraph()
    add_input!(graph, :a, 1)
    map!(identity, graph, :a, :b)
    map!(a -> (a, a), graph, :a, [:c, :d])

    target = ComputeGraph()

    ComputePipeline.move!(target, graph.b)
    @test !haskey(graph, :b)
    @test haskey(target, :b)
    @test target.b[] == 1
    @test target.b.parent.graph == target

    ComputePipeline.move!(target, graph.d)
    @test !haskey(graph, :c)
    @test !haskey(graph, :d)
    @test haskey(target, :c)
    @test haskey(target, :d)
    @test target.c[] == 1
    @test target.d[] == 1
    @test target.c.parent.graph == target
    @test target.d.parent.graph == target
end
