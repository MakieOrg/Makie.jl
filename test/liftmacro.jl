@testset "lift macro" begin
    x = Node(1.0)
    y = Node(2.0)
    z = (x = x, y = y)
    
    t1 = @lift($x + $y)
    @test t1[] == 3.0
    t2 = @lift($(z.x) - $(z.y))
    @test t2[] == -1.0

    f = Node(sin)

    t3 = @lift($f($x))
    @test t3[] == sin(x[])
    t4 = @lift($f($f($(z.x))))
    @test t4[] == sin(sin(z.x[]))

    arr = Node([1, 2, 3])
    t5 = @lift($arr[2])
    @test t5[] == 2

    nodes = [Node(1.0), Node(2.0)]
    t6 = @lift($(nodes[1]) + $(nodes[2]))
    @test t6[] == 3.0
end
