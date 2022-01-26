@testset "lift macro" begin
    x = Observable(1.0)
    y = Observable(2.0)
    z = (x = x, y = y)
    
    t1 = @lift($x + $y)
    @test t1[] == 3.0
    t2 = @lift($(z.x) - $(z.y))
    @test t2[] == -1.0

    f = Observable(sin)

    t3 = @lift($f($x))
    @test t3[] == sin(x[])
    t4 = @lift($f($f($(z.x))))
    @test t4[] == sin(sin(z.x[]))

    arrobs = Observable([1, 2, 3])
    t5 = @lift($arrobs[2])
    @test t5[] == 2

    observables = [Observable(1.0), Observable(2.0)]
    t6 = @lift($(observables[1]) + $(observables[2]))
    @test t6[] == 3.0
end
