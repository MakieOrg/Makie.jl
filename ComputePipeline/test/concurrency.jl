function delay(k, v)
    sleep(0.1)
    return v
end

function delay(v)
    sleep(0.1)
    return v
end

@testset "resolve world age" begin
    @testset "protected input" begin
        graph = ComputeGraph()
        add_input!(delay, graph, :first, 1)

        task = @async graph.first[]
        yield()
        @assert !istaskdone(task) "Task finished before a new input was pushed. (Test inconclusive)"
        # At this point we should have triggered resolve!(), stepped into the
        # callback and switched back out due to the sleep(). The initial value
        # of `first` should be locked in and get returned by the callback
        # once sleep finishes, even if we change it.
        graph.first = 5
        @test fetch(task) == 1
        @test isdirty(graph.first.parent)
        @test graph.inputs[:first].value == 5
        @test graph.first[] == 5
    end

    @testset "protected node" begin
        graph = ComputeGraph()
        add_input!(graph, :first, 1)
        map!(delay, graph, :first, :output)

        task = @async graph.output[]
        yield()
        @assert !istaskdone(task) "Task finished before a new input was pushed. (Test inconclusive)"
        @assert !isdirty(graph.first.parent) "Input did not resolve. (Test inconclusive)"
        # The same goes if a dependent yields.
        graph.first = 5
        @test fetch(task) == 1
        @test isdirty(graph.first.parent)
        @test isdirty(graph.output.parent)
        @test graph.output[] == 5
    end

    @testset "multi-access protected node" begin
        graph = ComputeGraph()
        add_input!(graph, :first, 1)
        map!(identity, graph, :first, :middle)
        map!(graph, [:first, :middle], :output) do f, m
            sleep(0.1)
            return f + m
        end

        task = @async graph.output[]
        yield()
        @assert !istaskdone(task) "Task finished before a new input was pushed. (Test inconclusive)"
        @assert !isdirty(graph.middle.parent) "first -> middle callback did not run. (Test inconclusive)"
        # Node protection must continue until all accesses of the current
        # resolve!() are finished.
        graph.first = 5
        @test fetch(task) == 1 + 1
        @test isdirty(graph.first.parent)
        @test isdirty(graph.middle.parent)
        @test isdirty(graph.output.parent)
        @test graph.output[] == 5 + 5
    end

    @testset "Competing resolves" begin
        # Attempts to test the following situation:
        # first resolve!() updates b (output of the Input)
        # b Input gets updated to a new value
        # second resolve!() starts, which should re-resolve b until first resolve
        # finishes using it for b -> shared
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        add_input!(delay, graph, :b, 2)
        add_input!(graph, :c, 3)
        map!(delay, graph, :b, :shared)
        map!(+, graph, [:a, :shared], :ab)
        map!(+, graph, [:shared, :c], :bc)

        # Could also deadlock because updates and resolve travel in opposite directions
        task = @async begin
            subtask = @async graph.ab[]
            yield()
            @assert !istaskdone(task) "Task finished before test could run"
            graph.b = 5
            graph.bc[]
            fetch(subtask)
        end

        for _ in 1:5
            sleep(0.1)
        end

        if istaskdone(task)
            @test isdirty(graph.ab.parent)
            @test fetch(task) == 1 + 2
            @test !isdirty(graph.bc.parent)
            @test graph.bc.value[] == 5 + 3
            @test graph.ab[] == 1 + 5
        else
            error("Possible deadlock detected")
        end
    end

    @testset "Distant competing resolves" begin
        # Similar to the above, both outputs shared inputs where one input is
        # used quickly and the other has some buffer edges
        graph = ComputeGraph()
        add_input!(graph, :in1, 1)
        add_input!(graph, :in2, 2)
        map!(identity, graph, :in1, :step1)
        map!(identity, graph, :in2, :step2)
        map!(graph, [:step1, :in2], :merge1) do a, b
            sleep(0.1)
            return a + b
        end
        map!(+, graph, [:step2, :in1], :merge2)

        # Could also deadlock because updates and resolve travel in opposite directions
        task = @async begin
            subtask = @async graph.merge1[]
            yield()
            @assert !istaskdone(task) "Task finished before test could run"
            graph.in1 = -1
            graph.in2 = -2
            graph.merge2[]
            fetch(subtask)
        end

        for _ in 1:5
            sleep(0.1)
        end

        if istaskdone(task)
            @test isdirty(graph.merge1.parent)
            @test fetch(task) == 1 + 2
            @test !isdirty(graph.merge2.parent)
            @test graph.merge2.value[] == -1 + -2
            @test graph.merge1[] == -1 + -2
        else
            error("Possible deadlock detected")
        end
    end
end

@testset "Connected Graphs" begin
    @testset "Back and forth" begin
        # This should not deadlock (which could happen with per-graph SpinLock())
        graph1 = ComputeGraph()
        add_input!(graph1, :a, 1)
        graph2 = ComputeGraph()
        add_input!(graph2, :b, graph1.a)
        map!(identity, graph1, graph2.b, :c)

        task = @async graph1.c[]
        for _ in 1:3
            sleep(0.1)
        end
        @test istaskdone(task)
    end

    @testset "Competing graph directions of independent edges" begin
        # With per-graph locks updating/resolving graphs in competing directions
        # could cause deadlocks if one doesn't lock all involved graphs before
        # yielding. (This test can easily miss deadlocks if lock() is called in
        # a code block at the start of resolve!().)
        graph1 = ComputeGraph()
        graph2 = ComputeGraph()
        add_input!(delay, graph1, :a, 1)
        add_input!(graph2, :b, graph1.a)
        add_input!(graph2, :x, 2)
        add_input!(graph1, :y, graph2.x)

        task = @async begin
            subtask = @async graph2.b[]
            yield()
            @assert !istaskdone(task) "Task finished before test could run"
            graph1.y[]
            fetch(subtask)
        end

        for _ in 1:3
            sleep(0.1)
        end

        if istaskdone(task)
            @test !isdirty(graph1.y.parent)
            @test graph1.y.value[] == 2
            @test !isdirty(graph2.b.parent)
            @test graph2.b.value[] == 1
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Competing update directions of mark_dirty!() and resolve!()" begin
        # If only the initial graph is locked this could cause state issues due
        # to overwriting. If graphs are successively locked in resolve!() and
        # mark_dirty!() this could deadlock

        @testset "During input resolve" begin
            # Somewhat easier/more obvious case - Input is in use during update
            graph1 = ComputeGraph()
            graph2 = ComputeGraph()
            add_input!(delay, graph1, :a, 1) # <--
            add_input!(graph2, :b, graph1.a)
            map!(identity, graph2, :b, :c)

            task = @async begin
                subtask = @async graph2.c[]
                yield()
                @assert !istaskdone(task) "Task finished before test could run"
                graph1.a = 5
                fetch(subtask)
            end

            for _ in 1:3
                sleep(0.1)
            end

            if istaskdone(task)
                @test fetch(task) == 1
                @test isdirty(graph1.a.parent)
                @test isdirty(graph2.b.parent)
                @test isdirty(graph2.c.parent)
                @test graph2.c[] == 5
            else
                error("Possible deadlock detected.")
            end
        end

        @testset "During parent graph edge resolve" begin
            # Input not in use, but still in parent graph
            graph1 = ComputeGraph()
            graph2 = ComputeGraph()
            add_input!(graph1, :a, 1)
            map!(delay, graph1, :a, :b) # <--
            add_input!(graph2, :c, graph1.b)
            map!(identity, graph2, :c, :d)

            task = @async begin
                subtask = @async graph2.d[]
                yield()
                @assert !istaskdone(task) "Task finished before test could run"
                graph1.a = 5
                fetch(subtask)
            end

            for _ in 1:3
                sleep(0.1)
            end

            if istaskdone(task)
                @test fetch(task) == 1
                @test isdirty(graph1.a.parent)
                @test isdirty(graph1.b.parent)
                @test isdirty(graph2.c.parent)
                @test isdirty(graph2.d.parent)
                @test graph2.c[] == 5
            else
                error("Possible deadlock detected.")
            end
        end

        @testset "During graph transition resolve" begin
            # Input not in use, but still in parent graph
            graph1 = ComputeGraph()
            graph2 = ComputeGraph()
            add_input!(graph1, :a, 1)
            map!(identity, graph1, :a, :b)
            add_input!(delay, graph2, :c, graph1.b) # <--
            map!(identity, graph2, :c, :d)

            task = @async begin
                subtask = @async graph2.d[]
                yield()
                @assert !istaskdone(task) "Task finished before test could run"
                graph1.a = 5
                fetch(subtask)
            end

            for _ in 1:3
                sleep(0.1)
            end

            if istaskdone(task)
                @test fetch(task) == 1
                @test isdirty(graph1.a.parent)
                @test isdirty(graph1.b.parent)
                @test isdirty(graph2.c.parent)
                @test isdirty(graph2.d.parent)
                @test graph2.c[] == 5
            else
                error("Possible deadlock detected.")
            end
        end

        @testset "During child graph resolve" begin
            # Input not in use, but still in parent graph
            graph1 = ComputeGraph()
            graph2 = ComputeGraph()
            add_input!(graph1, :a, 1)
            map!(identity, graph1, :a, :b)
            add_input!(graph2, :c, graph1.b)
            map!(delay, graph2, :c, :d) # <--

            task = @async begin
                subtask = @async graph2.d[]
                yield()
                @assert !istaskdone(task) "Task finished before test could run"
                graph1.a = 5
                fetch(subtask)
            end

            for _ in 1:3
                sleep(0.1)
            end

            if istaskdone(task)
                @test fetch(task) == 1
                @test isdirty(graph1.a.parent)
                @test isdirty(graph1.b.parent)
                @test isdirty(graph2.c.parent)
                @test isdirty(graph2.d.parent)
                @test graph2.c[] == 5
            else
                error("Possible deadlock detected.")
            end
        end
    end
end

@testset "Recursion from resolve!() callback" begin
    @testset "Set input from input" begin
        # Setting an input during it's own resolution is technically fine since
        # the value has already passed to the callback, but may still result in
        # a deadlock or broken state due to mark_dirty!() running during resolve!()
        graph = ComputeGraph()
        add_input!(graph, :a, 1) do k, v
            graph.a = v+1
            return v
        end
        map!(identity, graph, :a, :b)

        task = @async graph.b[]
        yield()

        if istaskdone(task)
            @test fetch(task) == 1
            @test isdirty(graph.a.parent)
            @test isdirty(graph.b.parent)
            @test graph.inputs[:a].value == 2
            @test graph.b[] == 2
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set input from dependent" begin
        # This should be easier to handle as Input.value is not used in the
        # a -> b callback. (This uses Input.output = ComputeEdge.inputs[1])
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do v
            graph.a = v+1
            return v
        end

        task = @async graph.b[]
        yield()

        if istaskdone(task)
            @test fetch(task) == 1
            @test isdirty(graph.a.parent)
            @test isdirty(graph.b.parent)
            @test graph.inputs[:a].value == 2
            @test graph.b[] == 2
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set reused Input from indirect dependent" begin
        # This could correctly handle a -> b, but then use the new a for a -> c,
        # desyncing b and c
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do v
            graph.a = v+1
            return v
        end
        map!(identity, graph, :a, :c)
        map!(+, graph, [:b, :c], :d)

        task = @async graph.d[]
        yield()

        if istaskdone(task)
            @test fetch(task) == 2
            @test isdirty(graph.a.parent)
            @test isdirty(graph.b.parent)
            @test isdirty(graph.c.parent)
            @test isdirty(graph.d.parent)
            @test graph.inputs[:a].value == 2
            @test graph.d[] == 4
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set Computed from direct dependent" begin
        @test_broken false
        # # Analogue to the first Input setting test
        # graph = ComputeGraph()
        # add_input!(graph, :a, 1)
        # map!(identity, graph, :a, :b)
        # map!(graph, :b, :c) do v
        #     # setting graph.a would just set the input again
        #     graph.b[] = v+1
        #     return v
        # end
        # map!(identity, graph, :c, :d)

        # task = @async graph.d[]
        # yield()

        # if istaskdone(task)
        #     @test fetch(task) == 1
        #     @test isdirty(graph.a.parent)
        #     @test isdirty(graph.b.parent)
        #     @test isdirty(graph.c.parent)
        #     @test isdirty(graph.d.parent)
        #     @test graph.inputs[:a].value == 2
        #     @test graph.d[] == 2
        # else
        #     error("Possible deadlock detected.")
        # end
    end

    @testset "Set Computed from indirect dependent" begin
        @test_broken false
        # # And the second one
        # graph = ComputeGraph()
        # add_input!(graph, :a, 1)
        # map!(identity, graph, :a, :b)
        # map!(identity, graph, :b, :c)
        # map!(graph, :c, :d) do v
        #     graph.b[] = v+1
        #     return v
        # end

        # task = @async graph.c[]
        # yield()

        # if istaskdone(task)
        #     @test fetch(task) == 1
        #     @test isdirty(graph.a.parent)
        #     @test isdirty(graph.b.parent)
        #     @test isdirty(graph.c.parent)
        #     @test isdirty(graph.d.parent)
        #     @test graph.inputs[:a].value == 2
        #     @test graph.d[] == 2
        # else
        #     error("Possible deadlock detected.")
        # end
    end

    @testset "Set reused Computed from indirect dependent" begin
        @test_broken false
        # graph = ComputeGraph()
        # add_input!(graph, :a, 1)
        # map!(identity, graph, :a, :b)
        # map!(graph, :b, :c) do v
        #     graph.b[] = v+1
        #     return v
        # end
        # map!(identity, graph, :b, :d)
        # map!(+, graph, [:c, :d], :e)

        # task = @async graph.e[]
        # yield()

        # if istaskdone(task)
        #     @test fetch(task) == 2
        #     @test isdirty(graph.a.parent)
        #     @test isdirty(graph.b.parent)
        #     @test isdirty(graph.c.parent)
        #     @test isdirty(graph.d.parent)
        #     @test isdirty(graph.e.parent)
        #     @test graph.inputs[:a].value == 2
        #     @test graph.e[] == 4
        # else
        #     error("Possible deadlock detected.")
        # end
    end
end

@testset "Recursion from resolve!() callback with forced evaluation" begin
    @test_broken false
    #=
    # Having output Observables causes any update to trigger onchange, which
    # then attempts to update every Observable connected to a dirty graph output
    # by resolving that output, settings obs.val and notifying it.
    # With that we have more potential for state overwrite and deadlock issues.
    # Also these tests should be careful not to cause infinite loops...
    @testset "Set input from input" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1) do k, v
            if v == 1
                graph.a = v+1
            end
            return v
        end
        map!(identity, graph, :a, :b)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.b, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test results == [1, 2]
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set input from dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do v
            if v == 1
                graph.a = v+1
            end
            return v
        end

        results = Int[]
        task = @async on(x -> push!(results, x), graph.b, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test results == [1, 2]
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set reused Input from indirect dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(graph, :a, :b) do v
            if v == 1
                graph.a = v+1
            end
            return v
        end
        map!(identity, graph, :a, :c)
        map!(+, graph, [:b, :c], :d)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.d, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test !isdirty(graph.c.parent)
            @test !isdirty(graph.d.parent)
            @test results == [2, 4]
        else
            error("Possible deadlock detected.")
        end
    end


    @testset "Set Computed from direct dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(identity, graph, :a, :b)
        map!(graph, :b, :c) do v
            if v == 1
                graph.b[] = v+1
            end
            return v
        end
        map!(identity, graph, :c, :d)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.d, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test !isdirty(graph.c.parent)
            @test !isdirty(graph.d.parent)
            @test results == [1, 2]
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set Computed from indirect dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(identity, graph, :a, :b)
        map!(identity, graph, :b, :c)
        map!(graph, :c, :d) do v
            if v == 1
                graph.b[] = v+1
            end
            return v
        end

        results = Int[]
        task = @async on(x -> push!(results, x), graph.d, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test !isdirty(graph.c.parent)
            @test !isdirty(graph.d.parent)
            @test results == [1, 2]
        else
            error("Possible deadlock detected.")
        end
    end

    @testset "Set reused Computed from indirect dependent" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 1)
        map!(identity, graph, :a, :b)
        map!(graph, :b, :c) do v
            graph.b[] = v+1
            return v
        end
        map!(identity, graph, :b, :d)
        map!(+, graph, [:c, :d], :e)

        results = Int[]
        task = @async on(x -> push!(results, x), graph.e, update = true)
        yield()

        if istaskdone(task)
            @test !isdirty(graph.a.parent)
            @test !isdirty(graph.b.parent)
            @test !isdirty(graph.c.parent)
            @test !isdirty(graph.d.parent)
            @test !isdirty(graph.e.parent)
            @test results == [2,]
        else
            error("Possible deadlock detected.")
        end
    end
    =#
end
