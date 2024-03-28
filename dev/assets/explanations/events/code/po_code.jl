# This file was generated, do not modify it. # hide
using Makie

po = Observable(0)

println("With low priority listener:")
on(po, priority = -1) do x
    println("Low priority: $x")
end
po[] = 1

println("\nWith medium priority listener:")
on(po, priority = 0) do x
    println("Medium blocking priority: $x")
    return Consume()
end
po[] = 2

println("\nWith high priority listener:")
on(po, priority = 1) do x
    println("High Priority: $x")
    return Consume(false)
end
po[] = 3
nothing # hide