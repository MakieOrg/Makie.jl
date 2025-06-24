@testset "BudgetedTimer" begin

    t = time_ns()
    dt = 1.0 / 30.0
    timer = Makie.BudgetedTimer(dt)

    @testset "Initialization" begin
        @test timer.target_delta_time == dt
        @test timer.budget == 0.0
        @test t < timer.last_time < time_ns()
    end

    @testset "sleep()" begin
        sleep(timer) # just in case for compilation

        t = time_ns()
        for _ in 1:100
            sleep(timer)
        end
        real_dt = 1.0e-9 * (time_ns() - t)

        @test 98 * dt < real_dt < 102 * dt
    end

    t = time_ns()
    dt = 0.03

    @testset "reset!()" begin
        Makie.reset!(timer, dt)

        @test timer.target_delta_time == dt
        @test timer.budget == 0.0
        @test t < timer.last_time < time_ns()
    end

    @testset "busysleep()" begin
        Makie.busysleep(timer)
        t = time_ns()
        for _ in 1:100
            Makie.busysleep(timer)
        end
        real_dt = 1.0e-9 * (time_ns() - t)

        @test 99.9 * dt < real_dt < 100.1 * dt
    end

    @testset "callbacks" begin
        counter = Ref(0)
        timer = Makie.BudgetedTimer(1.0 / 30.0, false) do timing
            counter[] += 1
        end
        sleep(0.5)
        @test counter[] == 0

        t = time_ns()
        Makie.start!(timer)
        sleep(1.0)
        Makie.stop!(timer)
        real_dt = 1.0e-9 * (time_ns() - t)
        wait(timer.task)
        N = counter[]

        @test real_dt * 30.0 - 4 < counter[] < real_dt * 30.0 + 4

        sleep(0.5)
        @test counter[] == N
    end
end
