using LinearAlgebra # HIDE
using Random:seed!  # HIDE
seed!(0)            # HIDE
                    # HIDE
x = randn(5)
y = randn(5)

for i in 1:5
    println(rpad("*"^i, 10, '-'), round(dot(x, y), digits=1))
end
