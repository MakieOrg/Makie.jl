using ComputePipeline
using Test

function set_task_tid!(task::Task, tid::Integer)
    task.sticky = true
    return ccall(:jl_set_task_tid, Cint, (Any, Cint), task, tid - 1)
end
function spawnat(f, tid)
    task = Task(f)
    set_task_tid!(task, tid)
    schedule(task)
    return task
end

@testset "Task/@spawn support" begin
    @testset "Basic Task return" begin
        graph = ComputeGraph()
        add_input!(graph, :in1, 1)
        add_input!(graph, :in2, 2)

        map!(graph, [:in1, :in2], :result) do x, y
            return Threads.@spawn (x + y)
        end

        # Wait for async task to complete
        sleep(0.1)
        @test graph[:result][] == 3
    end

    @testset "Long-running computation" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 5)

        register_computation!(graph, [:input], [:output]) do inputs, changed, cached
            return Threads.@spawn begin
                sleep(0.05)  # Simulate long computation
                (inputs.input^2,)
            end
        end

        # Immediately after update, result might not be ready
        update!(graph, input = 10)

        # Wait for task to complete
        sleep(0.1)
        @test graph[:output][] == 100
    end

    @testset "Multiple outputs with Task" begin
        graph = ComputeGraph()
        add_input!(graph, :a, 3)
        add_input!(graph, :b, 4)

        register_computation!(graph, [:a, :b], [:sum, :product]) do inputs, changed, cached
            return Threads.@spawn (inputs.a + inputs.b, inputs.a * inputs.b)
        end

        sleep(0.1)
        @test graph[:sum][] == 7
        @test graph[:product][] == 12
    end

    @testset "Task with updates" begin
        graph = ComputeGraph()
        add_input!(graph, :x, 1)

        counter = Ref(0)
        map!(graph, :x, :doubled) do x
            return Threads.@spawn begin
                counter[] += 1
                (2 * x)
            end
        end

        sleep(0.1)
        @test graph[:doubled][] == 2
        @test counter[] == 1

        update!(graph, x = 5)
        ComputePipeline.resolve!(graph[:doubled])
        sleep(0.1)
        @test graph[:doubled][] == 10
        @test counter[] == 2
    end

    @testset "Chained tasks" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 2)

        map!(graph, :input, :step1) do x
            return Threads.@spawn x * 2
        end

        map!(graph, :step1, :step2) do x
            return Threads.@spawn x + 3
        end
        graph[:step2][]
        sleep(0.15)
        @test graph[:step1][] == 4
        @test graph[:step2][] == 7
    end

    @testset "Task error handling" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 1)

        # This should log an error but not crash
        register_computation!(graph, [:input], [:output]) do inputs, changed, cached
            return Threads.@spawn begin
                error("Intentional error in task")
            end
        end

        # The task should fail gracefully
        sleep(0.1)
        # Output should remain uninitialized or unchanged
        @test_throws ComputePipeline.ResolveException{TaskFailedException} graph[:output][]
    end

    @testset "Mixed sync and async" begin
        graph = ComputeGraph()
        add_input!(graph, :input, 10)

        # Synchronous computation
        map!(x -> 2 * x, graph, :input, :sync_result)

        # Asynchronous computation
        register_computation!(graph, [:input], [:async_result]) do inputs, changed, cached
            return Threads.@spawn (inputs.input * 3,)
        end

        # Combine both
        map!(graph, [:sync_result, :async_result], :combined) do sync, async
            return (sync + async)
        end

        sleep(0.1)
        @test graph[:sync_result][] == 20
        @test graph[:async_result][] == 30
        @test graph[:combined][] == 50
    end
    @testset "properly polling result" begin
        graph = ComputePipeline.ComputeGraph()
        ComputePipeline.add_input!(graph, :a, rand(100))


        map!(graph, :a, :b) do x
            spawnat(2) do
                t = time()
                while time() - t < 1
                end
                return x .+ 1
            end
        end
        ComputePipeline.register_computation!(graph, [:b], [:c]) do input, changed, last
            return (input.b,)
        end
        result1 = copy(graph.c[]) # first resolve should be sync

        graph.a = rand(100)
        @test graph.c[] == result1
        @test !ComputePipeline.isdirty(graph.c)
        @test graph.b.parent.typed_edge[].async_pending[]
        while graph.b.parent.typed_edge[].async_pending[]
            sleep(0.01)
        end
        # Now after async is done, c should be dirty
        # And return a new value
        @test ComputePipeline.isdirty(graph.c)
        @test graph.c[] != result1
    end
end
